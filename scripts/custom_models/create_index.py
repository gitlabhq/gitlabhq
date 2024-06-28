import argparse
import glob
import os
import datetime
import re
import sqlite3
import requests
import json
from zipfile import ZipFile
from langchain.docstore.document import Document
from langchain_text_splitters import MarkdownHeaderTextSplitter
import tempfile

# Function to parse command-line arguments
def parse_arguments():
    parser = argparse.ArgumentParser(description="Generate and upload GitLab docs index.")
    parser.add_argument("--version_tag", help="GitLab version tag to include in the URL (e.g., v17.1.0-ee)")
    parser.add_argument("upload_url", help="URL to upload the database")
    parser.add_argument("private_token", help="GitLab personal access token")
    return parser.parse_args()

# Function to fetch documents from GitLab
def fetch_documents(version_tag=None):
    if version_tag:
        docs_url = f"https://gitlab.com/gitlab-org/gitlab/-/archive/{version_tag}/gitlab-{version_tag}.zip?path=doc"
    else:
        print("No version tag provided. Defaulting to fetching from master.")
        docs_url = f"https://gitlab.com/gitlab-org/gitlab/-/archive/master/gitlab-master.zip?path=doc"

    response = requests.get(docs_url)

    if response.status_code == 200:
        tmpdirname = tempfile.mkdtemp()
        zip_path = os.path.join(tmpdirname, "docs.zip")
        with open(zip_path, 'wb') as f:
            f.write(response.content)
        with ZipFile(zip_path, 'r') as zip_ref:
            zip_ref.extractall(tmpdirname)

        # Find the directory that was extracted
        extracted_dirs = [os.path.join(tmpdirname, name) for name in os.listdir(tmpdirname) if os.path.isdir(os.path.join(tmpdirname, name))]
        if not extracted_dirs:
            print("No directory found after extraction. Exiting.")
            return None

        print("Documents are fetched.")
        extracted_dir = extracted_dirs[0]
        print(f"Extracted documents to {extracted_dir}")
        return extracted_dir
    else:
        print(f"Failed to download documents. Status code: {response.status_code}")
        return None

# Function to process documents and create the database
def create_database(path, output_path):
    files = glob.glob(os.path.join(path, "doc/**/*.md"), recursive=True)
    if not files:
        print("No markdown files found. Exiting.")
        return

    documents = []

    # Read all the files
    for filename in files:
        with open(filename, "r") as f:
            doc = Document(
                page_content=f.read(),
                metadata={"filename": filename}
            )
            documents.append(doc)

    # Split content into chunks by its header
    headers_to_split_on = [
        ("#", "Header1"),
        ("##", "Header2"),
        ("###", "Header3"),
        ("####", "Header4"),
        ("#####", "Header5"),
    ]
    markdown_splitter = MarkdownHeaderTextSplitter(headers_to_split_on=headers_to_split_on)
    rows_to_insert = []

    for d in documents:
        md_header_splits = markdown_splitter.split_text(d.page_content)
        for chunk in md_header_splits:
            metadata = {**chunk.metadata, **d.metadata}
            rows_to_insert.append({"content": chunk.page_content, "metadata": metadata})

    # Process each row to yield better results
    def build_row_corpus(row):
        corpus = row['content']
        # Remove the preamble
        preamble_start = corpus.find('---')
        if preamble_start != -1:
            preamble_end = corpus.find('---', preamble_start + 1)
            corpus = corpus[preamble_end + 2:-1]
        if not corpus:
            return ''
        # Attach the titles to the corpus, these can still be useful
        corpus = ''.join(row['metadata'].get(f"Header{i}", '') for i in range(1, 6)) + ' ' + corpus
        # Stemming could be helpful, but it is already applied by the sqlite
        # Remove punctuation and set to lowercase, this should reduce the size of the corpus and allow
        # the query to be a bit more robust
        corpus = corpus.lower()
        corpus = re.sub(r'[^\w\s]', '', corpus)
        return corpus

    for r in rows_to_insert:
        r['processed'] = build_row_corpus(r)
    # sql_tuples = [(r['processed'], r['content'], r['metadata']['filename']) for r in rows_to_insert if r['processed']]
    sql_tuples = [(r['processed'], r['content'], json.dumps(r['metadata'])) for r in rows_to_insert if r['processed']]
    # Create the database
    conn = sqlite3.connect(output_path)
    c = conn.cursor()
    c.execute("CREATE VIRTUAL TABLE doc_index USING fts5(processed, content, metadata, tokenize='porter trigram');")
    c.executemany('INSERT INTO doc_index (processed, content, metadata) VALUES (?,?,?)', sql_tuples)
    conn.commit()
    conn.close()

# Function to upload the database file to GitLab model registry
def upload_to_gitlab(upload_url, file_path, private_token):
    headers = {"Authorization": f"Bearer {private_token}"}

    with open(file_path, 'rb') as f:
        files = {"file": f}
        response = requests.put(upload_url, headers=headers, files=files)

    if response.status_code in {200, 201}:
        print("Database uploaded successfully.")
    else:
        print(f"Upload failed with status code: {response.status_code}, response: {response.content}")

# Main function
def main():
    args = parse_arguments()

    # Fetch documents based on version tag (if provided)
    docs_path = fetch_documents(version_tag=args.version_tag)
    if not docs_path:
        print("Fetching documents failed. Exiting.")
        return

    # Create database
    timestamp = datetime.datetime.now().strftime("%Y%m%d%H%M%S")
    output_path = f"{docs_path}/created_index_docs_{timestamp}.db"
    create_database(docs_path, output_path)
    print(f"Database created at {output_path}")

    # Upload to GitLab
    if os.path.exists(output_path):
        upload_to_gitlab(args.upload_url, output_path, args.private_token)
    else:
        print("Database file not found. Upload skipped.")

if __name__ == "__main__":
    main()
