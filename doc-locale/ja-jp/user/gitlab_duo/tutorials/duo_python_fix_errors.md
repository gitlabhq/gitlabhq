---
stage: none
group: Tutorials
description: このチュートリアルでは、GitLab Duoを使用して、Pythonのショップアプリケーションのエラーを修正する方法について説明します。
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'チュートリアル: GitLab Duoを使用して、Pythonのショップアプリケーションのエラーを修正する'
---

<!-- vale gitlab_base.FutureTense = NO -->

このチュートリアルは、シリーズのパート2です。最初のチュートリアルでは、[GitLab Duoを使用して、Pythonでショップアプリケーションを作成しました](fix_code_python_shop.md)。

最初のチュートリアルに従い、コードが完全に動作する場合は、ルートからエラー処理を削除して、一般的なエラーを発生させます。たとえば、`try`ブロックと`catch`ブロック、および入力検証を削除します。次に、このチュートリアルに従って、GitLab Duoの助けを借りてそれらを追加し直します。

このチュートリアルでは、次のことを行います:

- 包括的なテストケースを作成し、テストを実行して、修正が必要なイシューを特定します。
- データベースのエラー処理と接続管理を改善します。
- データ検証を実装します。
- ルートに堅牢なエラー処理を追加します。
- Flaskアプリケーション設定を改善します。
- アプリケーションが正しく動作することを確認します。

## テストケースの作成 {#write-test-cases}

まず、チャットを使用して、Webアプリケーション用の包括的なテストケースを生成します。

適切に作成された包括的なテストケース:

- コードが機能していない場所を体系的に特定します。
- 標準条件とエラー条件の両方で、コードの各部分がどのように動作するかを正確に検討するのに役立ちます。
- 修正が必要なイシューの優先順位付きリストを作成します。
- 修正が機能しているかどうかをユーザーがすぐに検証できるようにします

テストケースを作成するには:

1. IDEでチャットを開き、次のように入力します:

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

1. チャットからの応答をレビューします。セットアップコード、フィクスチャ定義、および各ルートのテスト関数を含む、包括的なテスト計画を受け取る必要があります。

1. チャットの応答をレビューした後、フォローアップの質問をすることを検討してください:

   - テストフィクスチャの設計についてより深く理解するように努めてください:

     ```plaintext
     Can you explain why you're using these specific fixtures? What's the benefit of
     separating the app fixture from the client fixture?
     ```

   - 特定のエラー条件をテストする方法を理解するために、チャットに支援を求めてください:

     ```plaintext
     I'm particularly concerned about error handling for the POST and PUT routes.
     Can you enhance the tests to include more edge cases like invalid data types
     and missing required fields?
     ```

   - Flaskテストに関するより具体的なガイダンスについては、`/help`コマンドを使用してください:

     ```plaintext
     /help Flask testing with pytest
     ```

   - テストを高速化する方法をチャットに提案してもらいます:

     ```plaintext
     These tests seem comprehensive but might be slow when running the full suite.
     Are there any optimizations you'd suggest for the test setup?
     ```

1. 必要に応じてテスト計画を修正します。計画に満足したら、テストファイルの完全な実装についてチャットに尋ねてください:

   ```plaintext
   Based on the test plan, provide a complete implementation of the test_shop.py file that includes:
   1. Fixtures for setting up a test client and database
   2. Tests for each endpoint with both successful and error cases
   3. Proper cleanup after tests
   ```

1. 提案された実装を`tests/test_shop.py`ファイルにコピーします。テスト計画をどのように修正したかに応じて、実装は次のようになります:

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

Python Webアプリケーション用の包括的なテストケースが作成されました。

次に、テストを実行して、アプリケーションのイシューを特定します。

## アプリケーションイシューを特定するためのテストの実行 {#run-tests-to-identify-application-issues}

前のセクションで作成したテストを実行して、アプリケーションのイシューを特定します:

```python
pytest -v tests/test_shop.py
```

失敗したテストをレビューして、修正する必要があるイシューを特定します。

失敗したテスト結果は次のようになります。

### `test_delete_book` - 失敗 {#test_delete_book---failure}

このテストでは、書籍を削除しようとし、次に存在しない書籍（ID`999`）を削除しようとします。テストでは次の動作を想定しています:

- 削除が成功すると、`200`ステータスコードが返されます
- 存在しない書籍を削除しようとすると、`404`ステータスコードが返されます

このテストが失敗する理由は:

- `delete_article`関数が`app/database.py`ステータスを返しません。
- `delete_book`ルートは次のことを行いません:

  - 削除する前に書籍が存在するかどうかを確認します。
  - 存在しない書籍の場合を処理しないため、存在しない書籍の場合でも`200`ステータスコードが返されます。

### `test_update_book` - 部分的な失敗 {#test_update_book---partial-failure}

このテストでは、既存の書籍を更新してから、存在しない書籍を更新しようとします。存在しない書籍の部分は合格する可能性がありますが、イシューがあります:

- `update_article`関数が`database.py`ステータスを返しません。
- 入力データに対して検証は行われません。
- エラー処理がありません。

### `test_add_book` - 潜在的な失敗 {#test_add_book---potential-failure}

このテストでは、新しい書籍を追加し、応答にステータスコード201があるかどうかを確認します。このテストが失敗する理由は:

- `add_book`ルートに入力検証がありません。
- データが不足しているか無効な場合、エラー処理は行われません。
- `Article`クラスは、負の価格のような入力を検証しません。

### テストクライアントのセットアップ - 潜在的な失敗 {#test-client-setup---potential-failure}

テストフィクスチャが失敗する可能性がある理由は:

- アプリケーションがテスト設定を適切に処理しません。
- `create_app`関数は、提供されたテスト設定を使用しません。
- データベースパスがハードコードされているため、テストデータベースを使用するのが困難です。

### すべてのテストに影響する一般的なイシュー {#general-issues-affecting-all-tests}

コードベースのいくつかのイシューは、すべてのテストに影響します:

- データベース操作でエラー処理は行われません。
- アプリケーション全体で入力検証は行われません。
- ハードコードされた設定値。
- 重要な環境変数がありません。
- データベース関数で接続管理は行われません。

アプリケーションを堅牢でテスト可能にするには、これらのイシューに対処する必要があります。

### 失敗したテストを特定した後の次の手順 {#next-steps-after-identifying-failing-tests}

どのテストが失敗したかを確認した後、チャットとコード提案を使用して、次の方法でこれらのイシューに体系的に対処します:

- データベースのエラー処理と接続管理を改善します。
- アーティクルクラスにデータ検証を実装します。
- 適切なエラー処理をルート関数に追加します。
- アプリケーション設定を改善します。
- 修正をテストして検証します。

## データベースのエラー処理と接続管理を改善する {#improve-database-error-handling-and-connection-management}

ここで、コード提案（特にコード生成）を使用して、データベースのエラー処理と接続管理を改善します:

1. IDEで`app/database.py`ファイルを開きます。

1. まず、ハードコードされたデータベースパスを修正します。`DATABASE_PATH`が定義されている行にカーソルを置き、次のように入力します:

   ```python
   # Replace the hard coded database path with an environment variable for database path with a fallback
   DATABASE_PATH = 'bookstore.db'
   ```

1. 必要に応じて、生成されたコードをレビューして調整します。出力は次のようになります。

   ```python
   import os
   from dotenv import load_dotenv

   load_dotenv()

   # Use environment variable for database path with a fallback
   DATABASE_PATH = os.getenv('DATABASE_PATH', 'bookstore.db')
   ```

1. 次に、エラー処理を使用して`get_db_connection()`関数を改善します。関数の最後にカーソルを置き、次のように入力します:

   ```plaintext
   # Add in missing error handling and connection management.
   ```

1. 生成されたコードをレビューし、必要に応じて調整します。出力は次のようになります。

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

1. レコードが実際に削除されたかどうかを確認し、ステータスを返すように`delete_article`関数を改善します:

   ```plaintext
   # Modify the `delete_article` to return a boolean indicating success if article
   # was deleted, or failure if article was not found
   ```

1. 生成されたコードをレビューし、必要に応じて調整します。出力は次のようになります。

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

1. 最後に、成功を示すステータスを返すように`update_article`関数を改善します:

   ```plaintext
   # Modify the update_article function to return a boolean indicating success if article
   # was deleted, or failure if article was not found
   ```

1. 生成されたコードをレビューし、必要に応じて調整します。出力は次のようになります。

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

お疲れ様でした。コード提案を使用して、データベースのエラー処理と接続管理を改善しました。次に、チャットを使用して、`Article`クラスのデータ検証を実装します。

## データ検証の実装 {#implement-data-validation}

ここで、チャットを使用して、`Article`クラスの検証ルールを実装します:

1. IDEでチャットを開き、次のように入力します:

   ```plaintext
   How can I implement data validation rules for the Article class? I need to
   validate name as a non-empty string, price as a positive integer, quantity as
   a non-negative integer, and handle any validation errors.
   ```

1. 回答をレビューします。回答をイテレーションを行うために、フォローアップの質問をすることを検討してください:

   - 検証実装の特定の部分について説明するようにチャットに依頼します:

     ```plaintext
     Can you explain how the ValidationError class works in this implementation?
     Why is it defined as an inner class rather than separately?
     ```

   - より効率的な検証アプローチを提案するようにチャットにリクエストします:

     ```plaintext
     The validation logic in the constructor feels verbose. Is there a more efficient
     way to handle the validation, perhaps using Python decorators or a validation library?
     ```

   - 検証コードをリファクタリングするようにチャットに依頼します:

     ```plaintext
     Can you refactor the validation code to make it more maintainable? Perhaps
     extract the validation logic into separate methods?
     ```

1. リファクタリングされたコードの応答をレビューし、改善されたアーティクルクラスを実装します。出力は次のようになります。

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

1. オプション。より専門的な検証については、基本的な型チェックを超えた追加のPythonデータ検証手法について、チャットに問い合わせてください。

   必要に応じて、`/explain`スラッシュコマンドを使用して、追加の手法を理解してください。

Duoチャットを使用して、`Article`クラスのデータ検証を実装しました。

次に、コード提案を使用して、ルートのエラー処理を改善します。

## ルートのエラー処理の実装 {#implement-error-handling-in-routes}

ここで、コード提案を使用して、ルートのエラー処理を改善します:

1. IDEで`app/routes/shop.py`ファイルを開きます。

1. まず、GETルートに優れたエラー処理を追加しましょう。`get_all_books`関数の先頭にカーソルを置き、次のように入力します:

   ```plaintext
   # Implement error handling in the get_all_books function
   ```

1. 生成されたコードをレビューし、必要に応じて調整します。次のようになります:

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

1. 次に、コード提案を使用して、適切な検証とエラー処理で`add_book`関数を更新します。`add_book`関数の先頭に、次のように入力します:

   ```plaintext
   # Add validation for input data in the `add_book` route, implement proper
   # error handling, and enhance the `Article` class with validation for name,
   # price, and quantity
   ```

1. 生成されたコードをレビューし、必要に応じて調整します。次のようになります:

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

1. 書籍が存在するかどうかを確認し、エラーを適切に処理するように`delete_book`関数を更新します。`delete_book`関数の先頭に、次のように入力します:

   ```plaintext
   # Update the `delete_book` route to check if the book exists before deletion,
   # and return a 404 status code if the book does not exist
   ```

1. 生成されたコード</codeを検証し、必要に応じて調整します。次のようになります:

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

1. 最後に、コード提案を使用して、`update_book`関数のエラー処理を改善します。`update_book`関数の先頭に、次のように入力します:

   ```plaintext
   # Update the `update_book` route to check if the book exists before updating,
   # update the book with price and quantity validation, save the updated book,
   # and return a 500 status code if the book does not exist
   ```

1. 生成されたコード</codeを検証し、必要に応じて調整します。次のようになります:

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

お疲れ様でした。ルートのエラー処理が正常に改善されました。

次に、チャットを使用して、Flaskアプリケーション設定を改善します。

## Flaskアプリケーション設定を改善する {#improve-flask-application-configuration}

最後に行う改善は、チャットを使用してFlaskアプリケーション設定を改善することです。

1. IDEで`app/__init__.py`ファイルを開きます。

1. IDEでチャットを開き、次のように入力します:

   ```plaintext
   I need to improve this Flask application initialization code, specifically
   the security configuration and environment variable handling defined in the
   `create_app` function.
   ```

1. 回答をレビューします。`create_app`関数を改善するために、フォローアップの質問をすることを検討してください:

   - 特定のセキュリティ改善をリクエストします:

     ```plaintext
     What are the best practices for handling secret keys in a Flask application?
     How should I generate and manage them differently between development and production environments?
     ```

   - Flaskアプリケーション構造のベストプラクティスについて質問します:

     ```plaintext
     Are there any architectural improvements you'd suggest for this Flask application
     beyond configuration handling? How would professional Flask applications structure
     this differently?
     ```

   - 設定の選択肢の影響について説明するようにリクエストします:

     ```plaintext
     Can you explain the security implications of these configuration choices?
     What other Flask configurationsettings should I be aware of for a secure deployment?
     ```

1. 応答に基づいて、`create_app`関数を改善します。質問したフォローアップの質問に応じて、関数は次のようになります:

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

1. 次に、ハードコードするのではなくデータベースパスの環境変数を使用してテスト設定を適切に処理するために、`create_app`を更新します。次をチャットに入力します。

   ```plaintext
   How can I update create_app to properly handle test configuration and use
   environment variables
   ```

1. 生成されたコードをレビューし、必要に応じて調整します。次のようになります:

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

1. 最後に、適切な設定で改善された`.env`ファイルを作成します:

   ```python
   FLASK_APP=app
   FLASK_ENV=development
   SECRET_KEY=your_secure_secret_key_for_development
   DATABASE_PATH=bookstore.db
   ```

1. オプション。環境変数に関するセキュリティのベストプラクティスについてチャットにリクエストし、設定処理をさらに改善します:

   ```plaintext
   /security What are the best practices for handling environment variables and
   sensitive configuration in a Flask application?
   ```

   提供されたガイダンスを使用して、設定処理をさらに改善します。

## テストを再度実行し、アプリケーションが動作することを確認します {#run-tests-again-and-verify-the-application-works}

イシューを修正し、改善を実装したので、すべてが正しく動作することを確認しましょう:

1. すべてのテストに合格するように、テストを再度実行します:

   ```python
   pytest -v tests/test_shop.py
   ```

1. Flaskアプリケーションを起動します:

   ```python
   flask run
   ```

1. 有効な入力と無効な入力の両方を使用して、APIエンドポイントをテストします。これを行うには、次のエンドポイントで[Postman](https://www.postman.com/)や[cURL](https://curl.se/)のようなAPI開発ツールを使用します。

   - 有効なリクエストで`GET /books`。
   - 有効なIDで`GET /books/1`。
   - 無効なIDで`GET /books/999`。
   - 有効および無効（たとえば、フィールドの欠落、負の価格）データで`POST /books`。
   - 有効なデータと無効なデータで`PUT /books/1`。
   - `DELETE /books/1`。
   - 存在しないIDで`DELETE /books/999`。

1. エラー処理がすべてのエラーケースに対して正しく機能することを検証します。

1. オプション。エラー処理が正しく機能することを検証する方法をチャットに質問します。

## まとめ {#summary}

このチュートリアルでは、チャットとコード提案を使用して、次のことを行いました:

- 包括的なテストケースを作成し、テストを実行して、修正が必要なイシューを特定します。
- データベースのエラー処理と接続管理を改善します。
- データ検証を実装します。
- ルートに堅牢なエラー処理を追加します。
- Flaskアプリケーション設定を改善します。
- アプリケーションが正しく動作することを検証します。

これらの改善により、アプリケーションの信頼性、安全性、保守性が向上しました。

## 関連トピック {#related-topics}

- [GitLab Duoのユースケース](../use_cases.md)
- [GitLab Duoのスタートガイド](../../get_started/getting_started_gitlab_duo.md)
- ブログ投稿: [DevSecOpsエンジニアリングワークフローをGitLab Duoで効率化する](https://about.gitlab.com/blog/2024/12/05/streamline-devsecops-engineering-workflows-with-gitlab-duo/)
<!-- markdownlint-disable -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duoチャット](https://youtu.be/ZQBAuf-CTAY?si=0o9-xJ_ATTsL1oew)
<!-- Video published on 2024-04-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duoコード提案](https://youtu.be/ds7SG1wgcVM?si=MfbzPIDpikGhoPh7)
<!-- Video published on 2024-01-24 -->
<!-- markdownlint-enable -->
