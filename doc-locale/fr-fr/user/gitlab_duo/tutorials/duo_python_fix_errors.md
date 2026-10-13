---
stage: Tutorials
group: Tutorials
description: Tutoriel sur la façon de corriger les erreurs dans une application de boutique en Python avec GitLab Duo.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see <https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments>
title: 'Tutoriel : utiliser GitLab Duo pour corriger les erreurs dans une application de boutique Python'
---

<!-- vale gitlab_base.FutureTense = NO -->

Ce tutoriel est la deuxième partie d'une série. Dans le premier tutoriel, vous avez [utilisé GitLab Duo pour créer une application de boutique en Python](fix_code_python_shop.md).

Si vous avez suivi le premier tutoriel et que votre code fonctionne parfaitement, introduisez quelques erreurs courantes en supprimant la gestion des erreurs de vos routes. Par exemple, supprimez les blocs `try` et `catch` ainsi que la validation des entrées. Suivez ensuite ce tutoriel pour les réintégrer avec l'aide de GitLab Duo.

Dans ce tutoriel, vous allez :

- Rédiger des cas de test complets, exécuter les tests et identifier les problèmes à corriger.
- Améliorer la gestion des erreurs de base de données et la gestion des connexions.
- Implémenter la validation des données.
- Ajouter une gestion robuste des erreurs dans les routes.
- Améliorer la configuration de l'application Flask.
- Vérifier que l'application fonctionne correctement.

## Rédiger des cas de test {#write-test-cases}

Pour commencer, vous allez utiliser Chat pour générer des cas de test complets pour notre application web.

Des cas de test bien rédigés et complets permettent de :

- Identifier systématiquement les parties du code qui ne fonctionnent pas.
- Aider les utilisateurs à réfléchir précisément au comportement attendu de chaque partie du code, dans des conditions normales et d'erreur.
- Créer une liste priorisée des problèmes à corriger.
- Permettre aux utilisateurs de valider immédiatement si une correction fonctionne

Pour rédiger les cas de test :

1. Ouvrez Chat dans votre IDE et saisissez :

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

1. Examinez la réponse de Chat. Vous devriez recevoir un plan de test complet comprenant le code de configuration, les définitions de fixtures et les fonctions de test pour chaque route.

1. Après avoir examiné la réponse de Chat, envisagez de poser des questions de suivi :

   - Essayez de mieux comprendre la conception des fixtures de test :

     ```plaintext
     Can you explain why you're using these specific fixtures? What's the benefit of
     separating the app fixture from the client fixture?
     ```

   - Demandez à Chat de vous aider à comprendre comment tester des conditions d'erreur spécifiques :

     ```plaintext
     I'm particularly concerned about error handling for the POST and PUT routes.
     Can you enhance the tests to include more edge cases like invalid data types
     and missing required fields?
     ```

   - Pour obtenir des conseils plus spécifiques sur les tests Flask, utilisez la commande `/help` :

     ```plaintext
     /help Flask testing with pytest
     ```

   - Demandez à Chat de suggérer un moyen de rendre les tests plus rapides :

     ```plaintext
     These tests seem comprehensive but might be slow when running the full suite.
     Are there any optimizations you'd suggest for the test setup?
     ```

1. Modifiez le plan de test si nécessaire. Une fois que le plan vous convient, demandez à Chat une implémentation complète du fichier de test :

   ```plaintext
   Based on the test plan, provide a complete implementation of the test_shop.py file that includes:
   1. Fixtures for setting up a test client and database
   2. Tests for each endpoint with both successful and error cases
   3. Proper cleanup after tests
   ```

1. Copiez l'implémentation suggérée dans votre fichier `tests/test_shop.py`. Selon la façon dont vous avez modifié le plan de test, l'implémentation devrait ressembler à ce qui suit :

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

Vous avez maintenant créé des cas de test complets pour votre application web Python.

Ensuite, vous allez exécuter les tests pour identifier les problèmes dans l'application.

## Exécuter les tests pour identifier les problèmes de l'application {#run-tests-to-identify-application-issues}

Exécutez les tests créés dans la section précédente pour identifier les problèmes dans l'application :

```python
pytest -v tests/test_shop.py
```

Examinez les tests en échec pour identifier les problèmes que vous devez corriger.

Les résultats des tests en échec seront similaires à ce qui suit.

### `test_delete_book` - échec {#test_delete_book---failure}

Ce test tente de supprimer un livre, puis essaie de supprimer un livre inexistant (avec l'ID `999`). Le test attend le comportement suivant :

- La suppression réussie renvoie un code de statut `200`
- La tentative de suppression d'un livre inexistant renvoie un code de statut `404`

Ce test échoue parce que :

- La fonction `delete_article` dans `app/database.py` ne renvoie aucun statut.
- La route `delete_book` ne :

  - Vérifie pas si le livre existe avant la suppression.
  - Gère pas le cas d'un livre inexistant, et renverrait donc un code de statut `200` même pour les livres inexistants.

### `test_update_book` - échec partiel {#test_update_book---partial-failure}

Ce test met à jour un livre existant, puis essaie de mettre à jour un livre inexistant. La partie concernant le livre inexistant pourrait réussir, mais il y a des problèmes :

- La fonction `update_article` dans `database.py` ne renvoie pas de statut.
- Aucune validation n'est effectuée sur les données d'entrée.
- La gestion des erreurs est absente.

### `test_add_book` - échec potentiel {#test_add_book---potential-failure}

Ce test ajoute un nouveau livre et vérifie si la réponse a le code de statut 201. Ce test pourrait échouer parce que :

- Aucune validation des entrées dans la route `add_book`.
- Aucune gestion des erreurs si des données sont manquantes ou invalides.
- La classe `Article` ne valide pas les entrées comme les prix négatifs.

### Configuration du client de test - échec potentiel {#test-client-setup---potential-failure}

Les fixtures de test pourraient échouer parce que :

- L'application ne gère pas correctement la configuration de test.
- La fonction `create_app` n'utilise pas la configuration de test fournie.
- Le chemin de la base de données est codé en dur, ce qui rend difficile l'utilisation d'une base de données de test.

### Problèmes généraux affectant tous les tests {#general-issues-affecting-all-tests}

Plusieurs problèmes dans la base de code affectent tous les tests :

- Aucune gestion des erreurs dans les opérations de base de données.
- Aucune validation des entrées dans l'ensemble de l'application.
- Valeurs de configuration codées en dur.
- Variables d'environnement importantes manquantes.
- Aucune gestion des connexions dans les fonctions de base de données.

Vous devez résoudre ces problèmes pour rendre l'application robuste et testable.

### Prochaines étapes après l'identification des tests en échec {#next-steps-after-identifying-failing-tests}

Après avoir identifié les tests en échec, vous utiliserez Chat et Code Suggestions pour résoudre systématiquement ces problèmes en :

- Améliorant la gestion des erreurs de base de données et la gestion des connexions.
- Implémentant la validation des données dans la classe Article.
- Ajoutant une gestion appropriée des erreurs aux fonctions de routes.
- Améliorant la configuration de l'application.
- Testant et vérifiant les corrections.

## Améliorer la gestion des erreurs de base de données et la gestion des connexions {#improve-database-error-handling-and-connection-management}

Vous allez maintenant utiliser Code Suggestions (plus précisément la génération de code) pour améliorer la gestion des erreurs de base de données et la gestion des connexions :

1. Ouvrez le fichier `app/database.py` dans votre IDE.
1. Commencez par corriger le chemin de base de données codé en dur. Positionnez votre curseur à la ligne où `DATABASE_PATH` est défini, et saisissez ce qui suit :

   ```python
   # Replace the hard coded database path with an environment variable for database path with a fallback
   DATABASE_PATH = 'bookstore.db'
   ```

1. Examinez et ajustez le code généré si nécessaire. Il devrait être similaire à ce qui suit :

   ```python
   import os
   from dotenv import load_dotenv

   load_dotenv()

   # Use environment variable for database path with a fallback
   DATABASE_PATH = os.getenv('DATABASE_PATH', 'bookstore.db')
   ```

1. Ensuite, améliorez la fonction `get_db_connection()` avec la gestion des erreurs. Positionnez votre curseur à la fin de la fonction et saisissez ce qui suit :

   ```plaintext
   # Add in missing error handling and connection management.
   ```

1. Examinez le code généré et ajustez-le si nécessaire. Il devrait être similaire à ce qui suit :

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

1. Améliorez la fonction `delete_article` pour vérifier si un enregistrement a bien été supprimé et retourner un statut :

   ```plaintext
   # Modify the `delete_article` to return a boolean indicating success if article
   # was deleted, or failure if article was not found
   ```

1. Examinez le code généré et ajustez-le si nécessaire. Il devrait être similaire à ce qui suit :

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

1. Enfin, améliorez la fonction `update_article` pour retourner un statut indiquant le succès :

   ```plaintext
   # Modify the update_article function to return a boolean indicating success if article
   # was deleted, or failure if article was not found
   ```

1. Examinez le code généré et ajustez-le si nécessaire. Il devrait être similaire à ce qui suit :

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

Bravo, vous avez utilisé Code Suggestions pour améliorer la gestion des erreurs de base de données et la gestion des connexions. Ensuite, vous utiliserez Chat pour implémenter la validation des données pour la classe `Article`.

## Implémenter la validation des données {#implement-data-validation}

Vous allez maintenant utiliser Chat pour aider à implémenter des règles de validation pour la classe `Article` :

1. Ouvrez Chat dans votre IDE et saisissez :

   ```plaintext
   How can I implement data validation rules for the Article class? I need to
   validate name as a non-empty string, price as a positive integer, quantity as
   a non-negative integer, and handle any validation errors.
   ```

1. Examinez la réponse. Envisagez de poser des questions de suivi pour affiner la réponse :

   - Demandez à Chat d'expliquer une partie spécifique de l'implémentation de la validation :

     ```plaintext
     Can you explain how the ValidationError class works in this implementation?
     Why is it defined as an inner class rather than separately?
     ```

   - Demandez à Chat de suggérer une approche plus efficace pour la validation :

     ```plaintext
     The validation logic in the constructor feels verbose. Is there a more efficient
     way to handle the validation, perhaps using Python decorators or a validation library?
     ```

   - Demandez à Chat de refactoriser le code de validation :

     ```plaintext
     Can you refactor the validation code to make it more maintainable? Perhaps
     extract the validation logic into separate methods?
     ```

1. Examinez la réponse contenant le code refactorisé et implémentez la classe Article améliorée. Il devrait être similaire à ce qui suit :

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

1. Facultatif. Pour une validation plus spécialisée, demandez à Chat des techniques supplémentaires de validation des données Python au-delà de la vérification de type de base.

   Si nécessaire, utilisez la commande Slash `/explain` pour comprendre les techniques supplémentaires.

Vous avez utilisé GitLab Duo Chat pour implémenter la validation des données pour la classe `Article`.

Ensuite, vous utiliserez Code Suggestions pour améliorer la gestion des erreurs dans les routes.

## Implémenter la gestion des erreurs dans les routes {#implement-error-handling-in-routes}

Vous allez maintenant utiliser Code Suggestions pour améliorer la gestion des erreurs dans les routes :

1. Ouvrez le fichier `app/routes/shop.py` dans votre IDE.
1. Commencez par ajouter une meilleure gestion des erreurs aux routes GET. Positionnez votre curseur au début de la fonction `get_all_books`, et saisissez ce qui suit :

   ```plaintext
   # Implement error handling in the get_all_books function
   ```

1. Examinez le code généré et ajustez-le si nécessaire. Il devrait ressembler à ce qui suit :

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

1. Ensuite, utilisez Code Suggestions pour mettre à jour la fonction `add_book` avec une validation et une gestion des erreurs appropriées. Au début de la fonction `add_book`, saisissez ce qui suit :

   ```plaintext
   # Add validation for input data in the `add_book` route, implement proper
   # error handling, and enhance the `Article` class with validation for name,
   # price, and quantity
   ```

1. Examinez le code généré et ajustez-le si nécessaire. Il devrait ressembler à ce qui suit :

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

1. Mettez à jour la fonction `delete_book` pour vérifier si le livre existe et gérer les erreurs correctement. Au début de la fonction `delete_book`, saisissez ce qui suit :

   ```plaintext
   # Update the `delete_book` route to check if the book exists before deletion,
   # and return a 404 status code if the book does not exist
   ```

1. Vérifiez le code généré et ajustez-le si nécessaire. Il devrait ressembler à ce qui suit :

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

1. Enfin, utilisez Code Suggestions pour améliorer la gestion des erreurs de la fonction `update_book`. Au début de la fonction `update_book`, saisissez ce qui suit :

   ```plaintext
   # Update the `update_book` route to check if the book exists before updating,
   # update the book with price and quantity validation, save the updated book,
   # and return a 500 status code if the book does not exist
   ```

1. Vérifiez le code généré et ajustez-le si nécessaire. Il devrait ressembler à ce qui suit :

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

Bravo, vous avez amélioré avec succès la gestion des erreurs dans les routes.

Ensuite, vous utiliserez Chat pour améliorer la configuration de l'application Flask.

## Améliorer la configuration de l'application Flask {#improve-flask-application-configuration}

La dernière amélioration que vous allez apporter consiste à utiliser Chat pour améliorer la configuration de l'application Flask.

1. Ouvrez le fichier `app/__init__.py` dans votre IDE.
1. Ouvrez Chat dans votre IDE et saisissez :

   ```plaintext
   I need to improve this Flask application initialization code, specifically
   the security configuration and environment variable handling defined in the
   `create_app` function.
   ```

1. Examinez la réponse. Envisagez de poser des questions de suivi pour améliorer la fonction `create_app` :

   - Demandez des améliorations de sécurité spécifiques :

     ```plaintext
     What are the best practices for handling secret keys in a Flask application?
     How should I generate and manage them differently between development and production environments?
     ```

   - Renseignez-vous sur les bonnes pratiques de structure d'application Flask :

     ```plaintext
     Are there any architectural improvements you'd suggest for this Flask application
     beyond configuration handling? How would professional Flask applications structure
     this differently?
     ```

   - Demandez une explication des implications des choix de configuration :

     ```plaintext
     Can you explain the security implications of these configuration choices?
     What other Flask configuration settings should I be aware of for a secure deployment?
     ```

1. En vous basant sur la réponse, améliorez la fonction `create_app`. Selon les questions de suivi que vous avez posées, la fonction devrait ressembler à ce qui suit :

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

1. Ensuite, vous allez mettre à jour `create_app` pour gérer correctement la configuration de test en utilisant des variables d'environnement pour le chemin de base de données plutôt que de le coder en dur. Saisissez ce qui suit dans Chat.

   ```plaintext
   How can I update create_app to properly handle test configuration and use
   environment variables
   ```

1. Examinez le code généré et ajustez-le si nécessaire. Il devrait ressembler à ce qui suit :

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

1. Enfin, créez un fichier `.env` amélioré avec une configuration appropriée :

   ```python
   FLASK_APP=app
   FLASK_ENV=development
   SECRET_KEY=your_secure_secret_key_for_development
   DATABASE_PATH=bookstore.db
   ```

1. Facultatif. Demandez à Chat les bonnes pratiques de sécurité concernant les variables d'environnement pour améliorer davantage la gestion de la configuration :

   ```plaintext
   /security What are the best practices for handling environment variables and
   sensitive configuration in a Flask application?
   ```

   Utilisez les conseils fournis pour améliorer davantage la gestion de votre configuration.

## Exécuter à nouveau les tests et vérifier que l'application fonctionne {#run-tests-again-and-verify-the-application-works}

Maintenant que vous avez corrigé les problèmes et implémenté des améliorations, vérifions que tout fonctionne correctement :

1. Exécutez à nouveau les tests pour vous assurer que tous les tests réussissent :

   ```python
   pytest -v tests/test_shop.py
   ```

1. Démarrez l'application Flask :

   ```python
   flask run
   ```

1. Testez les points de terminaison de l'API avec des entrées valides et invalides. Pour ce faire, utilisez un outil de développement d'API comme [Postman](https://www.postman.com/) ou [curl](https://curl.se/) sur les points de terminaison suivants.

   - `GET /books` avec une requête valide.
   - `GET /books/1` avec un ID valide.
   - `GET /books/999` avec un ID invalide.
   - `POST /books` avec des données valides et invalides (par exemple, champs manquants, prix négatif).
   - `PUT /books/1` avec des données valides et invalides.
   - `DELETE /books/1`.
   - `DELETE /books/999` avec un ID inexistant.

1. Vérifiez que la gestion des erreurs fonctionne correctement pour tous les cas d'erreur.
1. Facultatif. Demandez à Chat comment valider que la gestion des erreurs fonctionne correctement.

## Résumé {#summary}

Dans ce tutoriel, vous avez utilisé Chat et Code Suggestions pour :

- Rédiger des cas de test complets, exécuter les tests et identifier les problèmes à corriger.
- Améliorer la gestion des erreurs de base de données et la gestion des connexions.
- Implémenter la validation des données.
- Ajouter une gestion robuste des erreurs dans les routes.
- Améliorer la configuration de l'application Flask.
- Vérifier que l'application fonctionne correctement.

Ces améliorations ont rendu l'application plus fiable, sécurisée et maintenable.

## Sujets connexes {#related-topics}

- [Cas d'utilisation de GitLab Duo](../use_cases.md)
- [Premiers pas avec GitLab Duo](../../get_started/getting_started_gitlab_duo.md).
- Article de blog : [Optimiser les workflows d'ingénierie DevSecOps avec GitLab Duo](https://about.gitlab.com/blog/streamline-devsecops-engineering-workflows-with-gitlab-duo/)
  <!-- markdownlint-disable -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Chat (agentique)](https://youtu.be/uG9-QLAJrrg?si=c25SR7DoRAep7jvQ)
  <!-- Video published on 2025-06-02 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Chat (non agentique)](https://youtu.be/ZQBAuf-CTAY?si=0o9-xJ_ATTsL1oew)
  <!-- Video published on 2024-04-18 -->
- <i class="fa-youtube-play" aria-hidden="true"></i> [GitLab Duo Code Suggestions](https://youtu.be/ds7SG1wgcVM?si=MfbzPIDpikGhoPh7)
  <!-- Video published on 2024-01-24 -->

<!-- markdownlint-enable -->
