---
stage: none
group: Tutorials
description: Tutorial on how to fix errors in a shop application in Python with GitLab Duo.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Use GitLab Duo to fix errors in a Python shop application'
---

<!-- vale gitlab_base.FutureTense = NO -->

This tutorial is part two in a series. In the first tutorial, you
[used GitLab Duo to create a shop application in Python](fix_code_python_shop.md).

If you followed the first tutorial and your code is working perfectly, introduce some common errors
by removing error handling from your routes. For example, remove `try` and `catch` blocks and input validation.
Then follow this tutorial to add them back with the help of GitLab Duo.

In this tutorial, you will:

- Write comprehensive test cases, run tests, and identify issues that need to be fixed.
- Improve database error handling and connection management.
- Implement data validation.
- Add robust error handling in routes.
- Improve the Flask application configuration.
- Verify the application works correctly.

## Write test cases

To start with, you will use Chat to generate comprehensive test cases for our
web application.

Well-written, comprehensive test cases:

- Systematically identify where code is not working.
- Help users to think through exactly how each part of the code should behave in both
  standard and error conditions.
- Create a prioritized list of issues that need fixing.
- Allow users to immediately validate if a fix is working

To write the test cases:

1. Open Chat in your IDE and enter:

   ```plaintext
   I need to write comprehensive tests for a Flask API for a bookstore inventory.
   Here's the current minimal test file:

   import pytest

   def test_dummy():
       """A dummy test that always passes."""
       assert True

   Can you help me write proper tests for the application? The API has routes for:
   - GET /books - Get all books
   - GET /books/<id> - Get a specific book
   - POST /books - Add a new book
   - PUT /books/<id> - Update a book
   - DELETE /books/<id> - Delete a book

   I want to test both successful operations and error handling.
   ```

1. Review the response from Chat. You should receive a comprehensive
   test plan including setup code, fixture definitions, and test functions for each route.

1. After reviewing Chat's response, consider asking follow-up questions:

   - Try to get a better understanding of the test fixture design:

     ```plaintext
     Can you explain why you're using these specific fixtures? What's the benefit of
     separating the app fixture from the client fixture?
     ```

   - Ask Chat to help you understand how to test specific error conditions:

     ```plaintext
     I'm particularly concerned about error handling for the POST and PUT routes.
     Can you enhance the tests to include more edge cases like invalid data types
     and missing required fields?
     ```

   - For more specific guidance on Flask testing, use the `/help` command:

     ```plaintext
     /help Flask testing with pytest
     ```

   - Ask Chat to suggest a way to make the tests run faster:

     ```plaintext
     These tests seem comprehensive but might be slow when running the full suite.
     Are there any optimizations you'd suggest for the test setup?
     ```

1. Amend the test plan as needed. After you are happy with the plan, ask Chat for
   a complete implementation of the test file:

   ```plaintext
   Based on the test plan, provide a complete implementation of the test_shop.py file that includes:
   1. Fixtures for setting up a test client and database
   2. Tests for each endpoint with both successful and error cases
   3. Proper cleanup after tests
   ```

1. Copy the suggested implementation into your `tests/test_shop.py` file. Depending
   on how you amended the test plan, the implementation should look similar to the following:

   ```python
   import pytest
   import json
   from app import create_app
   from app.database import initialize_database, get_db_connection

   @pytest.fixture
   def app():
       """Create and configure a Flask app for testing."""
       app = create_app({"TESTING": True, "DATABASE": "test_bookstore.db"})

       # Initialize the test database
       with app.app_context():
            initialize_database()

       yield app

       # Clean up the test database
       import os
       if os.path.exists("test_bookstore.db"):
          os.remove("test_bookstore.db")

   @pytest.fixture
   def client(app):
       """A test client for the app."""
       return app.test_client()

   @pytest.fixture
   def init_database(app):
       """Initialize the database with test data."""
       conn = get_db_connection()
       cursor = conn.cursor()

       # Add test books
       cursor.execute(
           "INSERT INTO articles (name, price, quantity) VALUES (?, ?, ?)",
           ("Test Book 1", 10.99, 5)
       )
       cursor.execute(
           "INSERT INTO articles (name, price, quantity) VALUES (?, ?, ?)",
           ("Test Book 2", 15.99, 10)
       )

       conn.commit()
       conn.close()

   def test_get_all_books(client, init_database):
       """Test retrieving all books."""
       response = client.get('/books')
       assert response.status_code == 200

       data = json.loads(response.data)
       assert len(data) == 2
       assert data[0]['name'] == 'Test Book 1'
       assert data[1]['name'] == 'Test Book 2'

   def test_get_book_by_id(client, init_database):
       """Test retrieving a specific book by ID."""
       # Test successful retrieval
       response = client.get('/books/1')
       assert response.status_code == 200

       data = json.loads(response.data)
       assert data['name'] == 'Test Book 1'
       assert data['price'] == 10.99

       # Test book not found
       response = client.get('/books/999')
       assert response.status_code == 404

   def test_add_book(client):
       """Test adding a new book."""
       new_book = {
           'name': 'New Test Book',
           'price': 20.99,
           'quantity': 15
       }

       response = client.post('/books',
                            data=json.dumps(new_book),
                            content_type='application/json')

       assert response.status_code == 201

       data = json.loads(response.data)
       assert data['name'] == 'New Test Book'
       assert data['price'] == 20.99
       assert data['quantity'] == 15
       assert 'id' in data

   def test_update_book(client, init_database):
       """Test updating an existing book."""
       update_data = {
           'price': 12.99,
           'quantity': 8
       }

       # Test successful update
       response = client.put('/books/1',
                           data=json.dumps(update_data),
                           content_type='application/json')

       assert response.status_code == 200

       data = json.loads(response.data)
       assert data['name'] == 'Test Book 1'  # Name unchanged
       assert data['price'] == 12.99  # Price updated
       assert data['quantity'] == 8  # Quantity updated

       # Test update for non-existent book
       response = client.put('/books/999',
                           data=json.dumps(update_data),
                           content_type='application/json')

       assert response.status_code == 404

   def test_delete_book(client, init_database):
       """Test deleting a book."""
       # Test successful deletion
       response = client.delete('/books/1')
       assert response.status_code == 200

       # Verify book was deleted
       response = client.get('/books/1')
       assert response.status_code == 404

       # Test deletion of non-existent book
       response = client.delete('/books/999')
       assert response.status_code == 404 # This might fail with current implementation
   ```

You have now created comprehensive test cases for your Python web application.

Next you will run the tests to identify the issues in the application.

## Run tests to identify application issues

Run the tests you created in the previous section to identify issues in the application:

```python
pytest -v tests/test_shop.py
```

Review the failing tests to identify issues that you must fix.

The failing test results will be similar to the following.

### `test_delete_book` - failure

This test attempts to delete a book, then tries to delete a non-existent book (with
ID `999`). The test expects the following behavior:

- Successful deletion returns a `200` status code
- Trying to delete a non-existent book returns a `404` status code

This test fails because:

- The `delete_article` function in `app/database.py` does not return any status.
- The `delete_book` route does not:

  - Check if the book exists before deletion.
  - Handle the case of a non-existent book, so it would return a `200` status code
    even for non-existent books.

### `test_update_book` - partial failure

This test updates an existing book and then tries to update a non-existent book.
The non-existent book part might pass, but there are issues:

- The `update_article` function in `database.py` does not return a status.
- No validation occurs on the input data.
- Error handling is missing.

### `test_add_book` - potential failure

This test adds a new book and checks if the response has status code 201. This
test might fail because:

- No input validation in the `add_book` route.
- No error handling if data is missing or invalid.
- The `Article` class does not validate inputs like negative prices.

### Test client setup - potential failure

The test fixtures might fail because the:

- Application does not properly handle test configuration.
- `create_app` function does not use the test configuration provided.
- Database path is hard coded, making it difficult to use a test database.

### General issues affecting all tests

Several issues in the codebase affect all tests:

- No error handling in database operations.
- No input validation throughout the application.
- Hard coded configuration values.
- Missing important environment variables.
- No connection management in database functions.

You must address these issues to make the application robust and testable.

### Next steps after identifying failing tests

After seeing which tests fail, you'll use Chat and Code Suggestions to systematically
address these issues by:

- Improving database error handling and connection management.
- Implementing data validation in the Article class.
- Adding proper error handling to route functions.
- Improving application configuration.
- Testing and verifying the fixes.

## Improve database error handling and connection management

Now, you will use Code Suggestions (specifically code generation) to improve the
database error handling and connection management:

1. Open the `app/database.py` file in your IDE.

1. First, fix the hard coded database path. Position your cursor at the line
   where `DATABASE_PATH` is defined, and enter the following:

   ```python
   # Replace the hard coded database path with an environment variable for database path with a fallback
   DATABASE_PATH = 'bookstore.db'
   ```

1. Review and adjust the generated code as needed. It should be similar to the following:

   ```python
   import os
   from dotenv import load_dotenv

   load_dotenv()

   # Use environment variable for database path with a fallback
   DATABASE_PATH = os.getenv('DATABASE_PATH', 'bookstore.db')
   ```

1. Next, improve the `get_db_connection()` function with error handling. Position
   your cursor at the end of the function and enter the following:

   ```plaintext
   # Add in missing error handling and connection management.
   ```

1. Review the generated code and adjust as needed. It should be similar to the
   following:

   ```python
   def get_db_connection():
    """
    Get a database connection.

    Returns:
        sqlite3.Connection: Database connection object

    Raises:
        sqlite3.Error: If connection to database fails
    """
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        conn.row_factory = sqlite3.Row
        return conn
    except sqlite3.Error as e:
        # Log the error
        print(f"Database connection error: {e}")
        raise
   ```

1. Improve the `delete_article` function to check if a record was actually
   deleted and return a status:

   ```plaintext
   # Modify the `delete_article` to return a boolean indicating success if article
   # was deleted, or failure if article was not found
   ```

1. Review the generated code and adjust as needed. It should be similar to the
   following:

   ```python
   def delete_article(article_id):
    """
    Delete an article from the database.

    Args:
        article_id (int): ID of the article to delete

    Returns:
        bool: True if article was deleted, False if article was not found
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute("DELETE FROM articles WHERE id = ?", (article_id,))

        deleted = cursor.rowcount > 0
        conn.commit()
        conn.close()
        return deleted
    except sqlite3.Error as e:
        print(f"Error deleting article: {e}")
        return False
   ```

1. Finally, improve the `update_article` function to return a status indicating success:

   ```plaintext
   # Modify the update_article function to return a boolean indicating success if article
   # was deleted, or failure if article was not found
   ```

1. Review the generated code and adjust as needed. It should be similar to the
   following:

   ```python
   def update_article(article):
    """
    Update an existing article in the database.

    Args:
        article (Article): Article object with updated values

    Returns:
        bool: True if article was updated, False if article was not found
    """
    try:
        conn = get_db_connection()
        cursor = conn.cursor()

        cursor.execute(
            "UPDATE articles SET name = ?, price = ?, quantity = ? WHERE id = ?",
            (article.name, article.price, article.quantity, article.id)
        )

        updated = cursor.rowcount > 0
        conn.commit()
        conn.close()
        return updated
    except sqlite3.Error as e:
        print(f"Error updating article: {e}")
        return False
   ```

Well done, you've used Code Suggestions to improve database error handling and
connection management. Next, you'll use Chat to implement data validation for the
`Article` class.

## Implement data validation

Now, you will use Chat to help implement validation rules for the `Article` class:

1. Open Chat in your IDE and enter:

   ```plaintext
   How can I implement data validation rules for the Article class? I need to
   validate name as a non-empty string, price as a positive integer, quantity as
   a non-negative integer, and handle any validation errors.
   ```

1. Review the response. Consider asking follow-up questions to iterate the response:

   - Ask Chat to explain a specific part of the validation implementation:

     ```plaintext
     Can you explain how the ValidationError class works in this implementation?
     Why is it defined as an inner class rather than separately?
     ```

   - Request Chat to suggest a more efficient approach to validation:

     ```plaintext
     The validation logic in the constructor feels verbose. Is there a more efficient
     way to handle the validation, perhaps using Python decorators or a validation library?
     ```

   - Ask Chat to refactor the validation code:

     ```plaintext
     Can you refactor the validation code to make it more maintainable? Perhaps
     extract the validation logic into separate methods?
     ```

1. Review the refactored code response and implement the improved Article class.
   It should be similar to the following:

   ```python
   class Article:
    """Article class for a bookstore inventory system."""

    class ValidationError(Exception):
        """Exception raised for validation errors in article attributes."""
        pass

    def __init__(self, name, price, quantity, article_id=None):
        """
        Initialize an article.

        Args:
            name (str): The name/title of the book
            price (float): The price of the book
            quantity (int): The quantity in stock
            article_id (int, optional): The unique identifier for the article

        Raises:
            ValidationError: If any of the inputs fail validation
        """
        self.id = article_id

        # Validate name
        if not name or not isinstance(name, str) or len(name.strip()) == 0:
            raise self.ValidationError("Article name must be a non-empty string")
        self.name = name.strip()

        # Validate price
        try:
            price_float = float(price)
            if price_float <= 0:
                raise self.ValidationError("Price must be a positive number")
            self.price = price_float
        except (ValueError, TypeError):
            raise self.ValidationError("Price must be a valid number")

        # Validate quantity
        try:
            quantity_int = int(quantity)
            if quantity_int < 0:
                raise self.ValidationError("Quantity cannot be negative")
            self.quantity = quantity_int
        except (ValueError, TypeError):
            raise self.ValidationError("Quantity must be a valid integer")

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

        Raises:
            ValidationError: If the dictionary is missing required fields or data fails validation
            KeyError: If a required key is missing from the dictionary
        """
        # Validate required fields
        required_fields = ["name", "price", "quantity"]
        for field in required_fields:
            if field not in data:
                raise cls.ValidationError(f"Missing required field: {field}")

        article_id = data.get("id")

        # Create and return new article with validation
        return cls(
            name=data["name"],
            price=data["price"],
            quantity=data["quantity"],
            article_id=article_id
        )
   ```

1. Optional. For more specialized validation, ask Chat about additional Python
   data validation techniques beyond basic type checking.

   If needed, use the `/explain` Slash command to understand any additional techniques.

You've used GitLab Duo Chat to implement data validation for the `Article` class.

Next you'll use Code Suggestions to improve error handling in the routes.

## Implement error handling in routes

Now, you'll use Code Suggestions to improve error handling in the routes:

1. Open the `app/routes/shop.py` file in your IDE.

1. First, let's add better error handling to the GET routes. Position your cursor
   at the beginning of the `get_all_books` function, and enter the following:

   ```plaintext
   # Implement error handling in the get_all_books function
   ```

1. Review the generated code and adjust as necessary. It should look similar to
   the following:

   ```python
   @shop_bp.route('', methods=['GET'])
   def get_all_books():
    """Get all books from the inventory."""
    try:
        books = database.get_all_articles()
        return jsonify([book.to_dict() for book in books])
    except Exception as e:
        # Log the error
        print(f"Error retrieving books: {e}")
        return jsonify({"error": "Failed to retrieve books", "details": str(e)}), 500
   ```

1. Next, use Code Suggestions to update the `add_book` function with proper
   validation and error handling. At the start of the `add_book` function, enter
   the following:

   ```plaintext
   # Add validation for input data in the `add_book` route, implement proper
   # error handling, and enhance the `Article` class with validation for name,
   # price, and quantity
   ```

1. Review the generated code and adjust as necessary. It should look similar to
   the following:

   ```python
   @shop_bp.route('', methods=['POST'])
   def add_book():
    """Add a new book to the inventory."""
    try:
        # Check if request contains JSON data
        if not request.is_json:
            return jsonify({"error": "Request must be JSON"}), 400

        data = request.get_json()

        # Validate required fields
        required_fields = ["name", "price", "quantity"]
        for field in required_fields:
            if field not in data:
                return jsonify({"error": f"Missing required field: {field}"}), 400

        # Create new book with validation
        try:
            new_book = Article(
                name=data['name'],
                price=data['price'],
                quantity=data['quantity']
            )
        except Article.ValidationError as e:
            return jsonify({"error": "Validation error", "details": str(e)}), 400

        # Add to database
        book_id = database.add_article(new_book)
        if book_id:
            created_book = database.get_article_by_id(book_id)
            return jsonify(created_book.to_dict()), 201
        else:
            return jsonify({"error": "Failed to add book to database"}), 500

    except Exception as e:
        # Log the error
        print(f"Error adding book: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500
   ```

1. Update the `delete_book` function to check if the book exists and handle errors
   properly. At the start of the `delete_book` function, enter the following:

   ```plaintext
   # Update the `delete_book` route to check if the book exists before deletion,
   # and return a 404 status code if the book does not exist
   ```

1. Check the generated code as adjust as necessary. It should look similar to
   the following:

   ```python
   @shop_bp.route('/<int:book_id>', methods=['DELETE'])
   def delete_book(book_id):
    """Delete a book from the inventory."""
    try:
        # Check if book exists before deletion
        existing_book = database.get_article_by_id(book_id)
        if not existing_book:
            return jsonify({"error": "Book not found"}), 404

        # Delete the book
        success = database.delete_article(book_id)
        if success:
            return jsonify({"message": "Book deleted successfully"}), 200
        else:
            return jsonify({"error": "Failed to delete book"}), 500

    except Exception as e:
        # Log the error
        print(f"Error deleting book: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500
   ```

1. Finally, use Code Suggestions to improve the error handling for the `update_book`
   function. At the start of the `update_book` function, enter the following:

   ```plaintext
   # Update the `update_book` route to check if the book exists before updating,
   # update the book with price and quantity validation, save the updated book,
   # and return a 500 status code if the book does not exist
   ```

1. Check the generated code and adjust as necessary. It should look similar to
   the following:

   ```python
   @shop_bp.route('/<int:book_id>', methods=['PUT'])
   def update_book(book_id):
    """Update an existing book."""
    try:
        # Check if request contains JSON data
        if not request.is_json:
            return jsonify({"error": "Request must be JSON"}), 400

        data = request.get_json()

        # Check if book exists
        existing_book = database.get_article_by_id(book_id)
        if not existing_book:
            return jsonify({"error": "Book not found"}), 404

        # Update book properties with validation
        try:
            if 'name' in data:
                existing_book.name = data['name']
            if 'price' in data:
                existing_book.price = float(data['price'])
                if existing_book.price <= 0:
                    return jsonify({"error": "Price must be a positive number"}), 400
            if 'quantity' in data:
                existing_book.quantity = int(data['quantity'])
                if existing_book.quantity < 0:
                    return jsonify({"error": "Quantity cannot be negative"}), 400
        except (ValueError, TypeError) as e:
            return jsonify({"error": "Invalid data format", "details": str(e)}), 400
        except Article.ValidationError as e:
            return jsonify({"error": "Validation error", "details": str(e)}), 400

        # Save updated book
        success = database.update_article(existing_book)
        if success:
            updated_book = database.get_article_by_id(book_id)
            return jsonify(updated_book.to_dict()), 200
        else:
            return jsonify({"error": "Failed to update book"}), 500

    except Exception as e:
        # Log the error
        print(f"Error updating book: {e}")
        return jsonify({"error": "Internal server error", "details": str(e)}), 500
   ```

Well done, you have successfully improved error handling in the routes.

Next, you will use Chat to improve the Flask application configuration.

## Improve Flask application configuration

The final improvement you're going to make is to use Chat to improve the Flask
application configuration.

1. Open the `app/__init__.py` file in your IDE.

1. Open Chat in your IDE and enter:

   ```plaintext
   I need to improve this Flask application initialization code, specifically
   the security configuration and environment variable handling defined in the
   `create_app` function.
   ```

1. Review the response. Consider asking follow-up questions to improve the `create_app` function:

   - Ask for specific security improvements:

     ```plaintext
     What are the best practices for handling secret keys in a Flask application?
     How should I generate and manage them differently between development and production environments?
     ```

   - Ask about Flask application structure best practices:

     ```plaintext
     Are there any architectural improvements you'd suggest for this Flask application
     beyond configuration handling? How would professional Flask applications structure
     this differently?
     ```

   - Ask for an explanation of the implications of the configuration choices:

     ```plaintext
     Can you explain the security implications of these configuration choices?
     What other Flask configurationsettings should I be aware of for a secure deployment?
     ```

1. Based on the response, improve the `create_app` function. Depending on the follow-up
   questions you asked, the function should look similar to the following:

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

1. Next, you'll update `create_app` to properly handle test configuration by using
   environment variables for the database path instead of hardcoding it. Enter the
   following into Chat.

   ```plaintext
   How can I update create_app to properly handle test configuration and use
   environment variables
   ```

1. Review the generated code and adjust as necessary. It should look similar to
   the following:

   ```python
   import os
   from flask import Flask
   from dotenv import load_dotenv

   load_dotenv()  # Load environment variables from .env file

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
        SECRET_KEY=os.getenv('SECRET_KEY', 'dev'),
        DATABASE_PATH=os.getenv('DATABASE_PATH', 'bookstore.db'),
        DEBUG=os.getenv('FLASK_ENV') == 'development',
    )

    # Override config with test config if provided
    if test_config:
        app.config.update(test_config)

    # Ensure instance folder exists
    os.makedirs(app.instance_path, exist_ok=True)

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
            "message": "Welcome to the Bookstore Inventory API",
            "version": "1.0",
            "endpoints": {
                "GET /books": "Get all books",
                "GET /books/<id>": "Get a specific book",
                "POST /books": "Add a new book",
                "PUT /books/<id>": "Update a book",
                "DELETE /books/<id>": "Delete a book"
            }
        }

    # Add error handlers
    @app.errorhandler(404)
    def not_found(e):
        return {"error": "Not found"}, 404

    @app.errorhandler(500)
    def server_error(e):
        return {"error": "Internal server error"}, 500

    return app
   ```

1. Finally, create an improved `.env` file with proper configuration:

   ```python
   FLASK_APP=app
   FLASK_ENV=development
   SECRET_KEY=your_secure_secret_key_for_development
   DATABASE_PATH=bookstore.db
   ```

1. Optional. Ask Chat for security best practices regarding environment variables
   to further improve the configuration handling:

   ```plaintext
   /security What are the best practices for handling environment variables and
   sensitive configuration in a Flask application?
   ```

   Use the provided guidance to further improve your configuration handling.

## Run tests again and verify the application works

Now that you've fixed the issues and implemented improvements, let's verify that
everything works correctly:

1. Run the tests again to make sure all tests pass:

   ```python
   pytest -v tests/test_shop.py
   ```

1. Start the Flask application:

   ```python
   flask run
   ```

1. Test the API endpoints with both valid and invalid inputs. To do this,
   use an API development tool like [Postman](https://www.postman.com/) or
   [curl](https://curl.se/) on the following endpoints.

   - `GET /books` with a valid request.
   - `GET /books/1` with a valid ID.
   - `GET /books/999` with an invalid ID.
   - `POST /books` with valid and invalid (for example, missing fields, negative price) data.
   - `PUT /books/1` with valid and invalid data.
   - `DELETE /books/1`.
   - `DELETE /books/999` with a non-existent ID.

1. Validate that the error handling works correctly for all error cases.

1. Optional. Ask Chat how to validate that the error handling works correctly.

## Summary

In this tutorial, you've used Chat and Code Suggestions to:

- Write comprehensive test cases, run tests, and identify issues that need to be fixed.
- Improve database error handling and connection management.
- Implement data validation.
- Add robust error handling in routes.
- Improve the Flask application configuration.
- Verify the application works correctly.

These improvements have made the application more reliable, secure, and maintainable.

## Related topics

- [GitLab Duo use cases](../use_cases.md)
- [Get started with GitLab Duo](../../get_started/getting_started_gitlab_duo.md).
- Blog post: [Streamline DevSecOps engineering workflows with GitLab Duo](https://about.gitlab.com/blog/2024/12/05/streamline-devsecops-engineering-workflows-with-gitlab-duo/)
<!-- markdownlint-disable -->
- <i class="fa-youtube-play" aria-hidden="true"></i>
  [GitLab Duo Chat](https://youtu.be/ZQBAuf-CTAY?si=0o9-xJ_ATTsL1oew)
<!-- Video published on 2024-04-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i>
  [GitLab Duo Code Suggestions](https://youtu.be/ds7SG1wgcVM?si=MfbzPIDpikGhoPh7)
<!-- Video published on 2024-01-24 -->
<!-- markdownlint-enable -->
