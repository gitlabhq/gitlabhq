---
stage: none
group: Tutorials
description: Tutorial on how to fix errors in a shop application in Python with GitLab Duo.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'GitLab Duo fix errors tutorial Python code files'
---

Tutorial: Use GitLab Duo to fix errors in a Python shop application

For the [Tutorial on using GitLab Duo to fix errors in a Python shop application](duo_python_fix_errors.md),
your Python web application is made up of the following files.

{{< tabs >}}

{{< tab title="app/models/article.py" >}}

```python
class Article:
    """Article class for a bookstore inventory system."""

    def __init__(self, name, price, quantity, article_id=None):
        """
        Initialize an article.

        Args:
            name (str): The name/title of the book
            price (float): The price of the book
            quantity (int): The quantity in stock
            article_id (int, optional): The unique identifier for the article
        """
        self.id = article_id
        self.name = name  # Missing validation
        self.price = float(price)  # Missing proper validation
        self.quantity = int(quantity)  # Missing proper validation

    def to_dict(self):
        """
        Convert the article to a dictionary.

        Returns:
            dict: Dictionary representation of the article
        """
        return {
            "id": self.id,
            "name": self.name,
            "price": self.price,
            "quantity": self.quantity
        }

    @classmethod
    def from_dict(cls, data):
        """
        Create an article from a dictionary.

        Args:
            data (dict): Dictionary with article data

        Returns:
            Article: New article instance
        """
        article_id = data.get("id")
        # Missing data validation before creating object
        return cls(
            name=data["name"],
            price=data["price"],
            quantity=data["quantity"],
            article_id=article_id
        )
```

{{< /tab >}}

{{< tab title="app/database.py" >}}

```python
import sqlite3
import os
from app.models.article import Article

# Hard coded database path instead of using environment variables
DATABASE_PATH = 'bookstore.db'

def get_db_connection():
    """
    Get a database connection.

    Returns:
        sqlite3.Connection: Database connection object
    """
    # Missing error handling
    # Missing connection management
    conn = sqlite3.connect(DATABASE_PATH)
    conn.row_factory = sqlite3.Row
    return conn

def initialize_database():
    """
    Initialize the database by creating the articles table if it doesn't exist.
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    # Create articles table
    cursor.execute('''
        CREATE TABLE IF NOT EXISTS articles (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NOT NULL,
            price REAL NOT NULL,
            quantity INTEGER NOT NULL
        )
    ''')

    conn.commit()
    conn.close()

def add_article(article):
    """
    Add a new article to the database.

    Args:
        article (Article): Article object to add

    Returns:
        int: ID of the newly added article
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        "INSERT INTO articles (name, price, quantity) VALUES (?, ?, ?)",
        (article.name, article.price, article.quantity)
    )

    # Get the ID of the newly inserted article
    article_id = cursor.lastrowid
    conn.commit()
    conn.close()
    return article_id

def get_article_by_id(article_id):
    """
    Get an article by its ID.

    Args:
        article_id (int): ID of the article to retrieve

    Returns:
        Article: Article object if found, None otherwise
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM articles WHERE id = ?", (article_id,))
    row = cursor.fetchone()
    conn.close()

    if row:
        return Article(
            name=row['name'],
            price=row['price'],
            quantity=row['quantity'],
            article_id=row['id']
        )
    return None

def get_all_articles():
    """
    Get all articles from the database.

    Returns:
        list: List of Article objects
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("SELECT * FROM articles")
    rows = cursor.fetchall()
    conn.close()

    articles = []
    for row in rows:
        article = Article(
            name=row['name'],
            price=row['price'],
            quantity=row['quantity'],
            article_id=row['id']
        )
        articles.append(article)

    return articles

def update_article(article):
    """
    Update an existing article in the database.

    Args:
        article (Article): Article object with updated values
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute(
        "UPDATE articles SET name = ?, price = ?, quantity = ? WHERE id = ?",
        (article.name, article.price, article.quantity, article.id)
    )

    conn.commit()
    conn.close()
    # Missing return value and error checking

def delete_article(article_id):
    """
    Delete an article from the database.

    Args:
        article_id (int): ID of the article to delete
    """
    conn = get_db_connection()
    cursor = conn.cursor()

    cursor.execute("DELETE FROM articles WHERE id = ?", (article_id,))

    conn.commit()
    conn.close()
    # Missing return value and error checking
```

{{< /tab >}}

{{< tab title="app/routes/shop.py" >}}

```python
from flask import Blueprint, request, jsonify
from app.models.article import Article
from app import database

# Create a blueprint for the shop routes
shop_bp = Blueprint('shop', __name__, url_prefix='/books')

@shop_bp.route('', methods=['GET'])
def get_all_books():
    """Get all books from the inventory."""
    books = database.get_all_articles()
    return jsonify([book.to_dict() for book in books])  # Missing error handling

@shop_bp.route('/<int:book_id>', methods=['GET'])
def get_book(book_id):
    """Get a specific book by ID."""
    book = database.get_article_by_id(book_id)
    if book:
        return jsonify(book.to_dict())
    return jsonify({"message": "Book not found"}), 404  # Incorrect error format

@shop_bp.route('', methods=['POST'])
def add_book():
    """Add a new book to the inventory."""
    data = request.get_json()

    # Missing input validation
    # Directly using input without validation
    new_book = Article(
        name=data['name'],
        price=data['price'],
        quantity=data['quantity']
    )

    book_id = database.add_article(new_book)
    created_book = database.get_article_by_id(book_id)
    return jsonify(created_book.to_dict()), 201

@shop_bp.route('/<int:book_id>', methods=['PUT'])
def update_book(book_id):
    """Update an existing book."""
    data = request.get_json()

    # Check if book exists
    existing_book = database.get_article_by_id(book_id)
    if not existing_book:
        return jsonify({"message": "Book not found"}), 404

    # Update book properties without validation
    if 'name' in data:
        existing_book.name = data['name']
    if 'price' in data:
        existing_book.price = float(data['price'])
    if 'quantity' in data:
        existing_book.quantity = int(data['quantity'])

    # Save updated book
    database.update_article(existing_book)

    # Missing error handling for the update operation
    updated_book = database.get_article_by_id(book_id)
    return jsonify(updated_book.to_dict())

@shop_bp.route('/<int:book_id>', methods=['DELETE'])
def delete_book(book_id):
    """Delete a book from the inventory."""
    # Missing check if book exists before deletion
    database.delete_article(book_id)
    return jsonify({"message": "Book deleted"}), 200
```

{{< /tab >}}

{{< tab title="tests/test_shop.py" >}}

```python
# Missing comprehensive test cases
import pytest

def test_dummy():
    """A dummy test that always passes."""
    assert True
```

{{< /tab >}}

{{< tab title="app/__init__.py" >}}

```python
from flask import Flask

def create_app(test_config=None):
    """
    Application factory for creating the Flask app.

    Args:
        test_config (dict, optional): Test configuration to override default config

    Returns:
        Flask: Configured Flask application
    """
    # Create and configure the app
    app = Flask(__name__)

    # Set default configuration
    app.config.from_mapping(
        SECRET_KEY='dev',  # Hard coded secret key
    )

    # Missing configuration from environment variables
    # Missing test config handling

    # Initialize database
    from app import database
    database.initialize_database()

    # Register blueprints
    from app.routes.shop import shop_bp
    app.register_blueprint(shop_bp)

    # Add a simple index route
    @app.route('/')
    def index():
        return {
            "message": "Welcome to the Bookstore Inventory API"
        }

    return app
```

{{< /tab >}}

{{< tab title=".env" >}}

```plaintext
# Missing many important environment variables
FLASK_APP=app
FLASK_ENV=development
```

{{< /tab >}}

{{< /tabs >}}

You will use Chat and Code Suggestions to identify and fix issues in these files.
