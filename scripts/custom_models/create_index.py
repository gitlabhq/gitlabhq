# Usage
# 1. Install requirements:
# pip install requests langchain langchain_text_splitter
# 2. Run the script:
# GLAB_TOKEN=<api_token> python3 scripts/custom_models/create_index.py --version_tag="v17.0.0"

import argparse
import glob
import os
import datetime
import re
import sqlite3
import sys
import requests
import json
from zipfile import ZipFile
from langchain.docstore.document import Document
from langchain_text_splitters import MarkdownHeaderTextSplitter
import tempfile
import logging

logging.basicConfig(level=logging.INFO)
logger = logging.getLogger(__name__)


# Function to parse command-line arguments
def parse_arguments():
    parser = argparse.ArgumentParser(description="Generate GitLab docs index.")

    parser.add_argument("-o", "--output_path",
                        help="Output path",
                        default="docs.db")
    parser.add_argument("-d", "--download",
                            help="Downloads GitLab docs from a reference. If disabled, assumes docs are in /docs",
                            action='store_true')
    parser.add_argument("--version_tag",
                        help="GitLab version tag to include in the URL (e.g., v17.1.0-ee). Only used when -d is set",
                        default="master")
    parser.add_argument("-u", "--upload",
                        help='''Uploads documentation as a generic package to a registry defined by project_id and base_url.
                             Requires GLAB_TOKEN to be defined with a GitLab PAT with api scope''',
                        action='store_true')
    parser.add_argument("--base_url",
                        help="URL to gitlab instance  uploading. Only used when -u is set",
                        default="https://gitlab.com")
    parser.add_argument("--project_id",
                        help="GitLab project ID. Only used when -u is set.",
                        default=278964)
    return parser.parse_args()


def execution_error(error_message):
    logger.error(error_message)
    sys.exit(1)


# Function to fetch documents from GitLab
def fetch_documents(version_tag):
    docs_url = f"https://gitlab.com/gitlab-org/gitlab/-/archive/{version_tag}/gitlab-{version_tag}.zip?path=doc"

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
            execution_error("No directory found after extraction. Exiting.")

        logger.info("Documents are fetched.")
        extracted_dir = extracted_dirs[0]
        logger.info(f"Extracted documents to {extracted_dir}")
        return extracted_dir
    else:
        execution_error(f"Failed to download documents. Status code: {response.status_code}")


def upload_url(base_url, project_id, version_tag):
    return f"{base_url}/api/v4/projects/{project_id}/packages/generic/gitlab-duo-local-documentation-index/{version_tag}/docs.db"


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


# Function to process documents and create the database
def create_database(path, output_path):
    files = glob.glob(os.path.join(path, "doc/**/*.md"), recursive=True)
    if not files:
        execution_error("No markdown files found")

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

    for r in rows_to_insert:
        r['processed'] = build_row_corpus(r)
    # sql_tuples = [(r['processed'], r['content'], r['metadata']['filename']) for r in rows_to_insert if r['processed']]
    sql_tuples = [(r['processed'], r['content'], json.dumps(r['metadata'])) for r in rows_to_insert if r['processed']]

    if os.path.exists(output_path):
        os.remove(output_path)
        logger.info(f"Deleted existing file at {output_path}")

    # Create the database
    conn = sqlite3.connect(output_path)
    c = conn.cursor()
    c.execute("CREATE VIRTUAL TABLE doc_index USING fts5(processed, content, metadata, tokenize='porter trigram');")
    c.execute("PRAGMA user_version = 1;")
    c.executemany('INSERT INTO doc_index (processed, content, metadata) VALUES (?,?,?)', sql_tuples)
    conn.commit()
    conn.close()


# Function to upload the database file to GitLab package registry
def upload_to_gitlab(upload_url, file_path, private_token):
    headers = {"Authorization": f"Bearer {private_token}"}

    with open(file_path, 'rb') as f:
        files = {"file": f}
        response = requests.put(upload_url, headers=headers, files=files)

    if response.status_code in {200, 201}:
        logger.info("Database uploaded successfully.")
    else:
        logger.error(f"Upload failed with status code: {response.status_code}, response: {response.content}")


if __name__ == "__main__":
    args = parse_arguments()

    if args.upload:
        private_token = os.environ['GLAB_TOKEN']

        if not private_token:
            execution_error("Private token must be set.")

    if args.download:
        docs_path = fetch_documents(version_tag=args.version_tag)
        if not docs_path:
            execution_error("Fetching documents failed")
    else:
        docs_path = ''

    output_path = args.output_path
    create_database(docs_path, output_path)
    logger.info(f"Database created at {output_path}")

    if args.upload:
        # Upload to GitLab
        if not os.path.exists(output_path):
            execution_error("Database file not found.")

        url = upload_url(args.base_url, args.project_id, args.version_tag)

        logger.info(f"Uploading to {url}")

        upload_to_gitlab(url, output_path, private_token)
