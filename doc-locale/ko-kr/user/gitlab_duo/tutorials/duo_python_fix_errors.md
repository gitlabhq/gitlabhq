---
stage: Tutorials
group: Tutorials
description: GitLab Duo를 사용하여 Python 도서 판매점 애플리케이션의 오류를 수정하는 방법에 대한 튜토리얼입니다.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: '튜토리얼: GitLab Duo를 사용하여 Python 도서 판매점 애플리케이션의 오류 수정'
---

<!-- vale gitlab_base.FutureTense = NO -->

이 튜토리얼은 시리즈의 두 번째 부분입니다. 첫 번째 튜토리얼에서는 [GitLab Duo를 사용하여 Python 도서 판매점 애플리케이션을 만들었습니다](fix_code_python_shop.md).

첫 번째 튜토리얼을 따라했고 코드가 완벽하게 작동한다면, 경로에서 오류 처리를 제거하여 일반적인 오류를 몇 가지 도입하세요. 예를 들어 `try` 및 `catch` 블록과 입력 검증을 제거합니다. 그런 다음 이 튜토리얼을 따라 GitLab Duo의 도움으로 다시 추가합니다.

이 튜토리얼에서는 다음을 수행합니다:

- 포괄적인 테스트 케이스를 작성하고, 테스트를 실행하며, 수정해야 할 이슈를 식별합니다.
- 데이터베이스 오류 처리 및 연결 관리를 개선합니다.
- 데이터 검증을 구현합니다.
- 경로에서 강력한 오류 처리를 추가합니다.
- Flask 애플리케이션 구성을 개선합니다.
- 애플리케이션이 올바르게 작동하는지 확인합니다.

## 테스트 케이스 작성 {#write-test-cases}

시작하려면 Chat을 사용하여 웹 애플리케이션에 대한 포괄적인 테스트 케이스를 생성합니다.

잘 작성되고 포괄적인 테스트 케이스:

- 코드가 작동하지 않는 위치를 체계적으로 식별합니다.
- 사용자가 표준 및 오류 조건 모두에서 코드의 각 부분이 어떻게 작동해야 하는지 정확하게 파악할 수 있도록 도와줍니다.
- 수정해야 할 이슈의 우선 순위 목록을 만듭니다.
- 사용자가 수정이 작동하는지 즉시 검증할 수 있습니다

테스트 케이스를 작성하려면:

1. IDE에서 Chat을 열고 다음을 입력합니다:

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

1. Chat의 응답을 검토합니다. 설정 코드, 픽스처 정의, 각 경로에 대한 테스트 함수를 포함하는 포괄적인 테스트 계획을 받아야 합니다.

1. Chat의 응답을 검토한 후 후속 질문을 하는 것을 고려하세요:

   - 테스트 픽스처 설계를 더 잘 이해하려고 노력합니다:

     ```plaintext
     Can you explain why you're using these specific fixtures? What's the benefit of
     separating the app fixture from the client fixture?
     ```

   - 특정 오류 조건을 테스트하는 방법을 이해할 수 있도록 Chat에 도움을 요청합니다:

     ```plaintext
     I'm particularly concerned about error handling for the POST and PUT routes.
     Can you enhance the tests to include more edge cases like invalid data types
     and missing required fields?
     ```

   - Flask 테스트에 대한 더 자세한 안내는 `/help` 명령을 사용합니다:

     ```plaintext
     /help Flask testing with pytest
     ```

   - 테스트를 더 빠르게 실행할 방법을 제안해 달라고 Chat에 요청합니다:

     ```plaintext
     These tests seem comprehensive but might be slow when running the full suite.
     Are there any optimizations you'd suggest for the test setup?
     ```

1. 필요에 따라 테스트 계획을 수정합니다. 계획에 만족한 후, Chat에 테스트 파일의 완전한 구현을 요청합니다:

   ```plaintext
   Based on the test plan, provide a complete implementation of the test_shop.py file that includes:
   1. Fixtures for setting up a test client and database
   2. Tests for each endpoint with both successful and error cases
   3. Proper cleanup after tests
   ```

1. `tests/test_shop.py` 파일에 제안된 구현을 복사합니다. 테스트 계획을 수정한 방식에 따라 구현은 다음과 유사해야 합니다:

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

이제 Python 웹 애플리케이션에 대한 포괄적인 테스트 케이스를 만들었습니다.

다음으로 테스트를 실행하여 애플리케이션의 이슈를 식별합니다.

## 테스트를 실행하여 애플리케이션 이슈 식별 {#run-tests-to-identify-application-issues}

애플리케이션의 이슈를 식별하기 위해 이전 섹션에서 만든 테스트를 실행합니다:

```python
pytest -v tests/test_shop.py
```

실패한 테스트를 검토하여 수정해야 할 이슈를 식별합니다.

실패한 테스트 결과는 다음과 유사합니다.

### `test_delete_book` - 실패 {#test_delete_book---failure}

이 테스트는 책을 삭제한 후 존재하지 않는 책(ID `999`)을 삭제하려고 시도합니다. 테스트는 다음 동작을 예상합니다:

- 성공적인 삭제는 `200` 상태 코드를 반환합니다
- 존재하지 않는 책을 삭제하려고 하면 `404` 상태 코드를 반환합니다

이 테스트가 실패하는 이유:

- `app/database.py`의 `delete_article` 함수가 상태를 반환하지 않습니다.
- `delete_book` 경로가 다음을 수행하지 않습니다:

  - 삭제 전에 책이 존재하는지 확인합니다.
  - 존재하지 않는 책의 경우를 처리하므로 존재하지 않는 책에 대해서도 `200` 상태 코드를 반환합니다.

### `test_update_book` - 부분 실패 {#test_update_book---partial-failure}

이 테스트는 기존 책을 업데이트한 후 존재하지 않는 책을 업데이트하려고 시도합니다. 존재하지 않는 책 부분은 통과할 수 있지만 이슈가 있습니다:

- `database.py`의 `update_article` 함수가 상태를 반환하지 않습니다.
- 입력 데이터에 대한 검증이 발생하지 않습니다.
- 오류 처리가 누락되어 있습니다.

### `test_add_book` - 잠재적 실패 {#test_add_book---potential-failure}

이 테스트는 새 책을 추가하고 응답의 상태 코드가 201인지 확인합니다. 이 테스트가 실패할 수 있는 이유:

- `add_book` 경로에 입력 검증이 없습니다.
- 데이터가 누락되거나 유효하지 않은 경우 오류 처리가 없습니다.
- `Article` 클래스가 음수 가격과 같은 입력을 검증하지 않습니다.

### 테스트 클라이언트 설정 - 잠재적 실패 {#test-client-setup---potential-failure}

테스트 픽스처가 다음으로 인해 실패할 수 있습니다:

- 애플리케이션이 테스트 구성을 제대로 처리하지 않습니다.
- `create_app` 함수가 제공된 테스트 구성을 사용하지 않습니다.
- 데이터베이스 경로가 하드코딩되어 있어 테스트 데이터베이스를 사용하기 어렵습니다.

### 모든 테스트에 영향을 주는 일반적인 이슈 {#general-issues-affecting-all-tests}

코드베이스의 여러 이슈가 모든 테스트에 영향을 줍니다:

- 데이터베이스 작업에 오류 처리가 없습니다.
- 애플리케이션 전체에 입력 검증이 없습니다.
- 하드코딩된 구성 값입니다.
- 중요한 환경 변수가 누락되어 있습니다.
- 데이터베이스 함수에 연결 관리가 없습니다.

애플리케이션을 강력하고 테스트 가능하게 하려면 이러한 이슈를 해결해야 합니다.

### 실패한 테스트를 식별한 후 다음 단계 {#next-steps-after-identifying-failing-tests}

어떤 테스트가 실패했는지 확인한 후 Chat과 코드 제안을 사용하여 이러한 이슈를 체계적으로 해결합니다:

- 데이터베이스 오류 처리 및 연결 관리를 개선합니다.
- Article 클래스에서 데이터 검증을 구현합니다.
- 경로 함수에 적절한 오류 처리를 추가합니다.
- 애플리케이션 구성을 개선합니다.
- 수정 사항을 테스트하고 확인합니다.

## 데이터베이스 오류 처리 및 연결 관리 개선 {#improve-database-error-handling-and-connection-management}

이제 코드 제안(특히 코드 생성)을 사용하여 데이터베이스 오류 처리 및 연결 관리를 개선합니다:

1. IDE에서 `app/database.py` 파일을 엽니다.
1. 먼저 하드코딩된 데이터베이스 경로를 수정합니다. `DATABASE_PATH`이 정의된 라인에 커서를 위치시키고 다음을 입력합니다:

   ```python
   # Replace the hard coded database path with an environment variable for database path with a fallback
   DATABASE_PATH = 'bookstore.db'
   ```

1. 필요에 따라 생성된 코드를 검토하고 조정합니다. 다음과 유사해야 합니다:

   ```python
   import os
   from dotenv import load_dotenv

   load_dotenv()

   # Use environment variable for database path with a fallback
   DATABASE_PATH = os.getenv('DATABASE_PATH', 'bookstore.db')
   ```

1. 다음으로 오류 처리를 통해 `get_db_connection()` 함수를 개선합니다. 함수의 끝에 커서를 위치시키고 다음을 입력합니다:

   ```plaintext
   # Add in missing error handling and connection management.
   ```

1. 생성된 코드를 검토하고 필요에 따라 조정합니다. 다음과 유사해야 합니다:

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

1. 실제로 삭제된 레코드를 확인하고 상태를 반환하는 `delete_article` 함수를 개선합니다:

   ```plaintext
   # Modify the `delete_article` to return a boolean indicating success if article
   # was deleted, or failure if article was not found
   ```

1. 생성된 코드를 검토하고 필요에 따라 조정합니다. 다음과 유사해야 합니다:

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

1. 마지막으로 성공을 나타내는 상태를 반환하는 `update_article` 함수를 개선합니다:

   ```plaintext
   # Modify the update_article function to return a boolean indicating success if article
   # was deleted, or failure if article was not found
   ```

1. 생성된 코드를 검토하고 필요에 따라 조정합니다. 다음과 유사해야 합니다:

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

잘 했습니다. 코드 제안을 사용하여 데이터베이스 오류 처리 및 연결 관리를 개선했습니다. 다음으로 Chat을 사용하여 `Article` 클래스에 대한 데이터 검증을 구현합니다.

## 데이터 검증 구현 {#implement-data-validation}

이제 Chat을 사용하여 `Article` 클래스의 검증 규칙을 구현합니다:

1. IDE에서 Chat을 열고 다음을 입력합니다:

   ```plaintext
   How can I implement data validation rules for the Article class? I need to
   validate name as a non-empty string, price as a positive integer, quantity as
   a non-negative integer, and handle any validation errors.
   ```

1. 응답을 검토합니다. 응답을 반복하기 위해 후속 질문을 하는 것을 고려합니다:

   - 검증 구현의 특정 부분을 설명해 달라고 Chat에 요청합니다:

     ```plaintext
     Can you explain how the ValidationError class works in this implementation?
     Why is it defined as an inner class rather than separately?
     ```

   - 검증에 대한 더 효율적인 방식을 제안해 달라고 Chat에 요청합니다:

     ```plaintext
     The validation logic in the constructor feels verbose. Is there a more efficient
     way to handle the validation, perhaps using Python decorators or a validation library?
     ```

   - 검증 코드를 리팩토링해 달라고 Chat에 요청합니다:

     ```plaintext
     Can you refactor the validation code to make it more maintainable? Perhaps
     extract the validation logic into separate methods?
     ```

1. 리팩토링된 코드 응답을 검토하고 개선된 Article 클래스를 구현합니다. 다음과 유사해야 합니다:

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

1. 선택 사항입니다. 더 특화된 검증을 위해 기본 유형 검사를 넘어선 추가 Python 데이터 검증 기술에 대해 Chat에 요청하세요.

   필요한 경우 `/explain` 슬래시 명령을 사용하여 추가 기술을 이해합니다.

GitLab Duo Chat을 사용하여 `Article` 클래스에 대한 데이터 검증을 구현했습니다.

다음으로 코드 제안을 사용하여 경로의 오류 처리를 개선합니다.

## 경로의 오류 처리 구현 {#implement-error-handling-in-routes}

이제 코드 제안을 사용하여 경로의 오류 처리를 개선합니다:

1. IDE에서 `app/routes/shop.py` 파일을 엽니다.
1. 먼저 GET 경로에 더 나은 오류 처리를 추가합니다. `get_all_books` 함수의 시작에 커서를 위치시키고 다음을 입력합니다:

   ```plaintext
   # Implement error handling in the get_all_books function
   ```

1. 생성된 코드를 검토하고 필요에 따라 조정합니다. 다음과 유사해야 합니다:

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

1. 다음으로 코드 제안을 사용하여 적절한 검증 및 오류 처리로 `add_book` 함수를 업데이트합니다. `add_book` 함수의 시작에서 다음을 입력합니다:

   ```plaintext
   # Add validation for input data in the `add_book` route, implement proper
   # error handling, and enhance the `Article` class with validation for name,
   # price, and quantity
   ```

1. 생성된 코드를 검토하고 필요에 따라 조정합니다. 다음과 유사해야 합니다:

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

1. 책이 존재하는지 확인하고 오류를 제대로 처리하는 `delete_book` 함수를 업데이트합니다. `delete_book` 함수의 시작에서 다음을 입력합니다:

   ```plaintext
   # Update the `delete_book` route to check if the book exists before deletion,
   # and return a 404 status code if the book does not exist
   ```

1. 생성된 코드를 검토하고 필요에 따라 조정합니다. 다음과 유사해야 합니다:

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

1. 마지막으로 코드 제안을 사용하여 `update_book` 함수의 오류 처리를 개선합니다. `update_book` 함수의 시작에서 다음을 입력합니다:

   ```plaintext
   # Update the `update_book` route to check if the book exists before updating,
   # update the book with price and quantity validation, save the updated book,
   # and return a 500 status code if the book does not exist
   ```

1. 생성된 코드를 검토하고 필요에 따라 조정합니다. 다음과 유사해야 합니다:

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

잘 했습니다. 경로의 오류 처리를 성공적으로 개선했습니다.

다음으로 Chat을 사용하여 Flask 애플리케이션 구성을 개선합니다.

## Flask 애플리케이션 구성 개선 {#improve-flask-application-configuration}

마지막으로 Chat을 사용하여 Flask 애플리케이션 구성을 개선합니다.

1. IDE에서 `app/__init__.py` 파일을 엽니다.
1. IDE에서 Chat을 열고 다음을 입력합니다:

   ```plaintext
   I need to improve this Flask application initialization code, specifically
   the security configuration and environment variable handling defined in the
   `create_app` function.
   ```

1. 응답을 검토합니다. `create_app` 함수를 개선하기 위해 후속 질문을 하는 것을 고려합니다:

   - 특정 보안 개선 사항을 요청합니다:

     ```plaintext
     What are the best practices for handling secret keys in a Flask application?
     How should I generate and manage them differently between development and production environments?
     ```

   - Flask 애플리케이션 구조 모범 사례에 대해 질문합니다:

     ```plaintext
     Are there any architectural improvements you'd suggest for this Flask application
     beyond configuration handling? How would professional Flask applications structure
     this differently?
     ```

   - 구성 선택 사항의 영향에 대한 설명을 요청합니다:

     ```plaintext
     Can you explain the security implications of these configuration choices?
     What other Flask configuration settings should I be aware of for a secure deployment?
     ```

1. 응답을 기반으로 `create_app` 함수를 개선합니다. 물어본 후속 질문에 따라 함수는 다음과 유사해야 합니다:

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

1. 다음으로 환경 변수를 사용하여 데이터베이스 경로를 하드코딩하는 대신 테스트 구성을 제대로 처리하도록 `create_app`을 업데이트합니다. Chat에 다음을 입력합니다.

   ```plaintext
   How can I update create_app to properly handle test configuration and use
   environment variables
   ```

1. 생성된 코드를 검토하고 필요에 따라 조정합니다. 다음과 유사해야 합니다:

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

1. 마지막으로 적절한 구성으로 개선된 `.env` 파일을 만듭니다:

   ```python
   FLASK_APP=app
   FLASK_ENV=development
   SECRET_KEY=your_secure_secret_key_for_development
   DATABASE_PATH=bookstore.db
   ```

1. 선택 사항입니다. 구성 처리를 더욱 개선하기 위해 환경 변수에 관한 보안 모범 사례를 Chat에 요청합니다:

   ```plaintext
   /security What are the best practices for handling environment variables and
   sensitive configuration in a Flask application?
   ```

   제공된 지침을 사용하여 구성 처리를 추가로 개선합니다.

## 테스트를 다시 실행하고 애플리케이션이 작동하는지 확인 {#run-tests-again-and-verify-the-application-works}

이슈를 수정하고 개선 사항을 구현했으므로 모든 것이 올바르게 작동하는지 확인합니다:

1. 테스트를 다시 실행하여 모든 테스트가 통과하는지 확인합니다:

   ```python
   pytest -v tests/test_shop.py
   ```

1. Flask 애플리케이션을 시작합니다:

   ```python
   flask run
   ```

1. 유효하고 유효하지 않은 입력 모두를 사용하여 API 엔드포인트를 테스트합니다. 이를 수행하려면 [Postman](https://www.postman.com/) 또는 [curl](https://curl.se/) 같은 API 개발 도구를 다음 엔드포인트에 사용합니다.

   - 유효한 요청으로 `GET /books`.
   - 유효한 ID로 `GET /books/1`.
   - 유효하지 않은 ID로 `GET /books/999`.
   - 유효하고 유효하지 않은(예: 누락된 필드, 음수 가격) 데이터로 `POST /books`.
   - 유효하고 유효하지 않은 데이터로 `PUT /books/1`.
   - `DELETE /books/1`.
   - 존재하지 않는 ID로 `DELETE /books/999`.

1. 모든 오류 경우에 대해 오류 처리가 올바르게 작동하는지 확인합니다.
1. 선택 사항입니다. 오류 처리가 올바르게 작동하는지 검증하는 방법을 Chat에 물어봅니다.

## 요약 {#summary}

이 튜토리얼에서는 Chat과 코드 제안을 사용하여 다음을 수행했습니다:

- 포괄적인 테스트 케이스를 작성하고, 테스트를 실행하며, 수정해야 할 이슈를 식별합니다.
- 데이터베이스 오류 처리 및 연결 관리를 개선합니다.
- 데이터 검증을 구현합니다.
- 경로에서 강력한 오류 처리를 추가합니다.
- Flask 애플리케이션 구성을 개선합니다.
- 애플리케이션이 올바르게 작동하는지 확인합니다.

이러한 개선 사항으로 애플리케이션이 더욱 안정적이고 안전하며 유지보수하기 쉬워졌습니다.

## 관련 항목 {#related-topics}

- [GitLab Duo 사용 사례](../use_cases.md)
- [GitLab Duo 시작하기](../../get_started/getting_started_gitlab_duo.md).
- 블로그 게시물: [GitLab Duo로 DevSecOps 엔지니어링 워크플로우 간소화](https://about.gitlab.com/blog/streamline-devsecops-engineering-workflows-with-gitlab-duo/)
  <!-- markdownlint-disable -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Chat (에이전틱)](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ)
  <!-- Video published on 2025-06-02 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Chat (비에이전틱)](https://youtu.be/ZQBAuf-CTAY?si=0o9-xJ_ATTsL1oew)
  <!-- Video published on 2024-04-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Code Suggestions](https://youtu.be/ds7SG1wgcVM?si=MfbzPIDpikGhoPh7)
  <!-- Video published on 2024-01-24 -->

<!-- markdownlint-enable -->
