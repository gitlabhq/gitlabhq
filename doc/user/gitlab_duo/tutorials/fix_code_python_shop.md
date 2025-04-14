---
stage: none
group: Tutorials
description: Tutorial on how to create a shop application in Python with GitLab Duo.
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://handbook.gitlab.com/handbook/product/ux/technical-writing/#assignments
title: 'Tutorial: Use GitLab Duo to create a shop application in Python'
---

<!-- vale gitlab_base.FutureTense = NO -->

You have been hired as a developer at an online bookstore. The current system for
managing inventory is a mix of spreadsheets and manual processes, leading to inventory
errors and delayed updates. Your team needs to create a web application that can:

- Track book inventory in real time.
- Enable staff to add new books as they arrive.
- Prevent common data entry errors, like negative prices or quantities.
- Provide a foundation for future customer-facing features.

This tutorial guides you through creating and debugging a [Python](https://www.python.org/)
web application with a database backend that meets these requirements.

You'll use [GitLab Duo Chat](../../gitlab_duo_chat/_index.md)
and [GitLab Duo Code Suggestions](../../project/repository/code_suggestions/_index.md)
to help you:

- Set up an organized Python project with standard directories and essential files.
- Configure the Python virtual environment.
- Install the [Flask](https://flask.palletsprojects.com/en/stable/) framework as the foundation
  for the web application.
- Install required dependencies, and prepare the project for development.
- Set up the Python configuration file and environment variables for Flask application
  development.
- Implement core features, including article models, database operations,
  API routes, and inventory management features.
- Test that the application works as intended, comparing your code with example code files.

## Before you begin

- [Install the latest version of Python](https://www.python.org/downloads/) on your system.
  You can ask Chat how to do that for your operating system.
- Make sure your organization has purchased a
  [GitLab Duo add-on subscription (either GitLab Duo Pro or Duo Enterprise)](https://about.gitlab.com/gitlab-duo/#pricing),
  and your administrator has [assigned you a seat](../../../subscriptions/subscription-add-ons.md#assign-gitlab-duo-seats).
- Install an extension in your preferred IDE:
  - [Web IDE](../../project/web_ide/_index.md): Access through your GitLab instance
  - [VS Code](../../../editor_extensions/visual_studio_code/setup.md)
  - [Visual Studio](../../../editor_extensions/visual_studio/setup.md)
  - [JetBrains IDE](../../../editor_extensions/jetbrains_ide/_index.md)
  - [Neovim](../../../editor_extensions/neovim/setup.md)
- Authenticate with GitLab from the IDE, using either
  [OAuth](../../../integration/google.md) or a
  [personal access token with the `api` scope](../../profile/personal_access_tokens.md#create-a-personal-access-token).

## Use GitLab Duo Chat and Code Suggestions

In this tutorial, you will use Chat and Code Suggestions to create the Python
web application. Multiple ways exist to use these features.

### Use GitLab Duo Chat

You can use Chat in the GitLab UI, the Web IDE, or in your IDE.

#### Use Chat in the GitLab UI

1. In the upper-right corner, select **GitLab Duo Chat**. A drawer opens on the
   right side of your browser tab.
1. Enter your question in the chat input box. Press **Enter**, or select **Send**.
   It might take a few seconds for the interactive AI chat to produce an answer.

#### Use Chat in the Web IDE

1. Open the Web IDE:
   1. In the GitLab UI, on the left sidebar, select **Search or go to** and find your project.
   1. Select a file. Then in the upper right, select **Edit > Open in Web IDE**.
1. Open Chat by using one of these methods:
   - On the left sidebar, select **GitLab Duo Chat**.
   - In the file that you have open in the editor, select some code.
     1. Right-click and select **GitLab Duo Chat**.
     1. Select **Explain selected code**, **Generate Tests**, or **Refactor**.
   - Use the keyboard shortcut: <kbd>ALT</kbd>+<kbd>d</kbd> (on Windows and Linux) or
     <kbd>Option</kbd>+<kbd>d</kbd> (on Mac).
1. In the message box, enter your question. Press **Enter**, or select **Send**.

#### Use Chat in your IDE

How you use Chat in your IDE differs depending on which IDE you use.

{{< tabs >}}

{{< tab title="VS Code" >}}

1. In VS Code, open a file. The file does not need to be a file in a Git repository.
1. On the left sidebar, select **GitLab Duo Chat** ({{< icon name="duo-chat" >}}).
1. In the message box, enter your question. Press **Enter**, or select **Send**.
1. In the chat pane, on the top right corner, select **Show Status** to show information
   in the Command Palette.

You can also interact with Duo Chat while you're working with a subset of code.

1. In VS Code, open a file. The file does not need to be a file in a Git repository.
1. In the file, select some code.
1. Right-click and select **GitLab Duo Chat**.
1. Select an option, or **Open Quick Chat** and ask a question, like
   `Can you simplify this code?` and press <kbd>Enter</kbd>.

For more information, see [Use GitLab Duo Chat in VS Code](../../gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-vs-code).

{{< /tab >}}

{{< tab title="JetBrains IDEs" >}}

1. Open a project in a JetBrains IDE that supports Python, such as
   [PyCharm](https://www.jetbrains.com/pycharm/), or [IntelliJ IDEA](https://www.jetbrains.com/idea/).
1. Open GitLab Duo Chat in either a [chat window](../../gitlab_duo_chat/_index.md#in-a-chat-window)
   or an [editor window](../../gitlab_duo_chat/_index.md#in-the-editor-window).

For more information, see [Use GitLab Duo Chat in JetBrains IDEs](../../gitlab_duo_chat/_index.md#use-gitlab-duo-chat-in-jetbrains-ides).

{{< /tab >}}

{{< /tabs >}}

### Use Code Suggestions

To use Code Suggestions:

1. Open your Git project in a
   [supported IDE](../../project/repository/code_suggestions/supported_extensions.md#supported-editor-extensions).
1. Add the project as a remote of your local repository using
   [`git remote add`](../../../topics/git/commands.md#git-remote-add).
1. Add your project directory, including the hidden `.git/` folder, to your IDE workspace or project.
1. Author your code.
   As you type, suggestions are displayed. Code Suggestions provides code snippets
   or completes the current line, depending on the cursor position.

1. Describe the requirements in natural language.
   Code Suggestions generates functions and code snippets based on the context provided.

1. When you receive a suggestion, you can do any of the following:
   - To accept a suggestion, press <kbd>Tab</kbd>.
   - To accept a partial suggestion, press either <kbd>Control</kbd>+<kbd>Right arrow</kbd> or
     <kbd>Command</kbd>+<kbd>Right arrow</kbd>.
   - To reject a suggestion, press <kbd>Esc</kbd>.
   - To ignore a suggestion, keep typing as you usually would.

For more information, see the [Code Suggestions documentation](../../project/repository/code_suggestions/_index.md).

Now that you know how to use Chat and Code Suggestions, let's start building the
web application. First, you will create an organized Python project structure.

## Create the project structure

To start with, you need a well-organized project structure that follows
Python best practices. A proper structure makes your code more maintainable, testable,
and easier for other developers to understand.

You can use Chat to help you understand Python project organization conventions
and generate the appropriate files. This saves you time researching best practices, and
ensures you do not miss critical components.

1. Open Chat in your IDE and enter:

   ```plaintext
   What is the recommended project structure for a Python web application? Include
   common files, and explain the purpose of each file.
   ```

   This prompt helps you understand Python project organization before creating files.

1. Create a new folder for the Python project and create a directory and file structure
   based on Chat's response. It will probably be similar to the following:

   ```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py
   └── tests/
       ├── __init__.py
       └── test_shop.py
   ```

1. You must populate the `.gitignore` file. Enter the following into Chat:

   ```plaintext
   Generate a .gitignore file for a Python project that uses Flask, SQLite, and
   virtual environments. Include common IDE files.
   ```

1. Copy the response into the `.gitignore` file.

1. For the `README` file, enter the following into Chat:

   ```plaintext
   Generate a README.md file for a Python web application that manages a bookstore
   inventory. Make sure that it includes all sections for requirements, setup, and usage.
   ```

You have now created a properly-structured Python project that follows industry
best practices. This organization makes your code easier to maintain and test.
Next, you'll set up your development environment to start writing code.

## Set up the development environment

A properly isolated development environment prevents dependency conflicts and makes
your application deployable.

You will use Chat to help you set up a Python virtual environment and create a
`requirements.txt` file with the right dependencies. This ensures you have a stable
foundation for development.

```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt <= File you are updating
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py
   └── tests/
       ├── __init__.py
       └── test_shop.py
```

1. Optional. Ask Chat about how Python and Flask work together to produce
   web applications.

1. Use Chat to understand the best practices for setting up a Python environment:

   ```plaintext
   What are the recommended steps for setting up a Python virtual environment with
   Flask? Include information about requirements.txt and pip.
   ```

   Ask any follow-up questions that you need to. For example:

   ```plaintext
   What does the requirements.txt do in a Python web app?
   ```

1. Based on the response, first create and activate a virtual environment
   (for example, on MacOS using Homebrew's `python3` package):

   ```plaintext
   python3 -m venv myenv
   source myenv/bin/activate
   ```

1. You must also create a `requirements.txt` file. Ask Chat the following:

   ```plaintext
   What should be included in requirements.txt for a Flask web application with
   SQLite database and testing capabilities? Include specific version numbers.
   ```

   Copy the response to the `requirements.txt` file.

1. Install the dependencies named in the `requirements.txt` file:

   ```plaintext
   pip install -r requirements.txt
   ```

Your development environment is now configured with all necessary dependencies
isolated in a virtual environment to prevent conflicts. Next, you'll configure
the project's package and environment settings.

## Configure the project

Proper configuration, including environment variables, enables your application
to run consistently across different environments.

You'll use Code Suggestions to help generate and refine the configuration.
Then, you'll ask Chat to explain the purpose of each setting, so you understand
what you're configuring and why.

1. You have already created a Python configuration file called `setup.py` in your
   project folder:

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py <= File you are updating
      ├── .gitignore
      ├── .env
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   Open this file, and enter this comment at the top of the file:

   ```plaintext
   # Populate this setup.py configuration file for a Flask web application
   # Include dependencies for Flask, testing, and database functionality
   # Use semantic versioning
   ```

   Code Suggestions generates the configuration for you.

1. Optional. Select the generated configuration code and use the following
   [slash commands](../../gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands):

   - Use [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code)
     to understand what each configuration setting does.
   - Use [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)
     to identify potential improvements in the configuration structure.

1. Review and adjust the generated code as needed.

   If you are not sure what you can adjust in the configuration file, ask Chat.

   If you want to ask Chat what to adjust, do so in the IDE in the `setup.py`
   file, instead of in the GitLab UI. This provides Chat with
   [the context you're working in](../../gitlab_duo_chat/_index.md#the-context-chat-is-aware-of),
   including the `setup.py` file you just created.

   ```plaintext
   You have used Code Suggestions to generate a Python configuration file, `setup.py`,
   for a Flask web application. This file includes dependencies for Flask, testing,
   and database functionality. If I were to review this file, what might I want
   to change and adjust?
   ```

1. Save the file.

### Set the environment variables

Next, you're going to use both Chat and Code Suggestions to set the environment variables.

1. In Chat, ask the following:

   ```plaintext
   In a Python project, what environment variables should be set for a Flask application in development mode? Include database configuration.
   ```

1. You have already created a `.env` file to store environment variables.

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py
      ├── .gitignore
      ├── .env <= File you are updating
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   Open this file, and enter the following comment at the top of the file, including
   the environment variables that Chat recommended:

   ```plaintext
   # Populate this .env file to store environment variables
   # Include the following
   # ...
   # Use semantic versioning
   ```

1. Review and adjust the generated code as needed, and save the file.

You have configured your project and set the environment variables. This ensures
your application can be deployed consistently across different environments. Next,
you'll create the application code for the inventory system.

## Create the application code

The Flask web framework has three core components:

- Models: Contains the data and business logic, and the database model. Specified in the `article.py` file.
- Views: Handles HTTP requests and responses. Specified in the `shop.py` file.
- Controller: Manages data storage and retrieval. Specified in the `database.py` file.

You will use Chat and Code Suggestions to help you define each of these three components
in three files in your Python project structure:

- `article.py` defines the models component, specifically the database model.
- `shop.py` defines the views component, specifically the API routes.
- `database.py` defines the controller component.

### Create the article file to define the database model

Your bookstore needs database models and operations to manage inventory effectively.

To create the application code for the bookstore inventory system, you will
use an article file to define the database model for articles.

You will use Code Suggestions to help generate the code, and Chat to
implement best practices for data modeling and database management.

1. You have already created an `article.py` file:

   ```plaintext
      python-shop-app/
      ├── LICENSE
      ├── README.md
      ├── requirements.txt
      ├── setup.py
      ├── .gitignore
      ├── .env
      ├── app/
      │   ├── __init__.py
      │   ├── models/
      │   │   ├── __init__.py
      │   │   └── article.py <= File you are updating
      │   ├── routes/
      │   │   ├── __init__.py
      │   │   └── shop.py
      │   └── database.py
      └── tests/
          ├── __init__.py
          └── test_shop.py
   ```

   In this file, use Code Suggestions
   and enter the following:

   ```plaintext
   # Create an Article class for a bookstore inventory system
   # Include fields for: name, price, quantity
   # Add data validation for each field
   # Add methods to convert to/from dictionary format
   ```

1. Optional. Use the following [slash commands](../../gitlab_duo_chat/examples.md#gitlab-duo-chat-slash-commands):

   - Use [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code)
     to understand how the article class works and its design patterns.
   - Use, [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)
     to identify potential improvements in the class structure and methods.

1. Review and adjust the generated code as needed, and save the file.

Next you will define the API routes.

### Create the shop file to define the API routes

Now that you have created the article file to define the database model, you will
create the API routes.

API routes are crucial for a web application because they:

- Define the public API for clients to interact with your application.
- Map HTTP requests to the appropriate code in your application.
- Handle input validation and error responses.
- Transform data between your internal models and the JSON format expected by API clients.

For your bookstore inventory system, these routes will allow staff to:

- View all books in inventory.
- Look up specific books by ID.
- Add new books as they arrive.
- Update book information such as price or quantity.
- Remove books that are no longer needed.

In Flask, routes are functions that handle requests to specific URL endpoints.
For example, a route for `GET /books` would return a list of all books, while
`POST /books` would add a new book to the inventory.

You will use Chat and Code Suggestions to create these routes in the `shop.py`
file that you've already set up in your project structure:

```plaintext
python-shop-app/
├── LICENSE
├── README.md
├── requirements.txt
├── setup.py
├── .gitignore
├── .env
├── app/
│   ├── __init__.py
│   ├── models/
│   │   ├── __init__.py
│   │   └── article.py
│   ├── routes/
│   │   ├── __init__.py
│   │   └── shop.py <= File you are updating
│   └── database.py
└── tests/
   ├── __init__.py
   └── test_shop.py
```

#### Create the Flask application and routes

1. Open the `shop.py` file. To use Code Suggestions, enter this comment
   at the top of the file:

  ```plaintext
  # Create Flask routes for a bookstore inventory system
  # Include routes for:
  # - Getting all books (GET /books)
  # - Getting a single book by ID (GET /books/<id>)
  # - Adding a new book (POST /books)
  # - Updating a book (PUT /books/<id>)
  # - Deleting a book (DELETE /books/<id>)
  # Use the Article class from models.article and database from database.py
  # Include proper error handling and HTTP status codes
  ```

1. Review the generated code. It should include:

   - Import statements for Flask, request, and `jsonify`.
   - Import statements for your Article class and database module.
   - Route definitions for all CRUD operations (Create, Read, Update, Delete).
   - Proper error handling and HTTP status codes.

1. Optional. Use these slash commands:

   - Use [`/explain`](../../gitlab_duo_chat/examples.md#explain-selected-code)
     to understand how the Flask routing works.
   - Use [`/refactor`](../../gitlab_duo_chat/examples.md#refactor-code-in-the-ide)
     to identify potential improvements.

1. If the generated code doesn't fully meet your needs, or you want to understand
   how to improve it, you can ask Chat from within the `shop.py` file:

  ```plaintext
  Can you suggest improvements for my Flask routes in this shop.py file?
  I want to ensure that:
  1. The routes follow RESTful API design principles
  2. Responses include appropriate HTTP status codes
  3. Input validation is handled properly
  4. The code follows Flask best practices
  ```

1. You also need to create the Flask application instance in the `__init__.py`
   file inside the `app` directory. Open this file and use Code Suggestions to
   generate the appropriate code:

  ```plaintext
  # Create a Flask application factory
  # Configure the app with settings from environment variables
  # Register the shop blueprint
  # Return the configured app
  ```

1. Save both files.

### Create the database file to manage data storage and retrieval

Finally, you will create the database operations code. You have already created
a `database.py` file:

```plaintext
   python-shop-app/
   ├── LICENSE
   ├── README.md
   ├── requirements.txt
   ├── setup.py
   ├── .gitignore
   ├── .env
   ├── app/
   │   ├── __init__.py
   │   ├── models/
   │   │   ├── __init__.py
   │   │   └── article.py
   │   ├── routes/
   │   │   ├── __init__.py
   │   │   └── shop.py
   │   └── database.py <= File you are updating
   └── tests/
       ├── __init__.py
       └── test_shop.py
```

1. Enter the following into Chat:

   ```plaintext
   Generate a Python class that manages SQLite database operations for a bookstore inventory. Include:
   - Context manager for connections
   - Table creation
   - CRUD operations
   - Error handling
   Show the complete code with comments.
   ```

1. Review and adjust the generated code as needed, and save the file.

You have successfully created the foundational code for your inventory
management system and defined the core components
of a Python web application built using the Flask framework.

Next you'll check your created code against example code files.

## Check your code against example code files

The following examples show complete, working code that should be similar to the
code you end up with after following the tutorial.

{{< tabs >}}

{{< tab title=".gitignore" >}}

This file shows standard Python project exclusions:

```plaintext
# Virtual Environment
myenv/
venv/
ENV/
env/
.venv/

# Python
__pycache__/
*.py[cod]
*$py.class
*.so
.Python
build/
develop-eggs/
dist/
downloads/
eggs/
.eggs/
lib/
lib64/
parts/
sdist/
var/
wheels/
*.egg-info/
.installed.cfg
*.egg

# SQLite database files
*.db
*.sqlite
*.sqlite3

# Environment variables
.env
.env.local
.env.*.local

# IDE specific files
.idea/
.vscode/
*.swp
*.swo
.DS_Store
```

{{< /tab >}}

{{< tab title="README.md" >}}
<!-- markdownlint-disable MD029 -->
A comprehensive `README` file with setup and usage instructions.

````markdown
# Bookstore Inventory Management System

A Python web application for managing bookstore inventory, built with Flask and SQLite.

## Features

- Track book inventory in real time.
- Add, update, and remove books.
- Data validation to prevent common errors.
- RESTful API for inventory management.

## Requirements

- Python 3.8 or higher.
- Flask 2.2.0 or higher.
- SQLite 3.

## Installation

1. Clone the repository:

   ```shell
   git clone https://gitlab.com/your-username/python-shop-app.git
   cd python-shop-app
   ```

2. Create and activate a virtual environment:

   ```shell
   python -m venv myenv
   source myenv/bin/activate  # On Windows: myenv\Scripts\activate
   ```

3. Install dependencies:

   ```shell
   pip install -r requirements.txt
   ```

4. Set up environment variables:

   Copy `.env.example` to `.env` and modify as needed.

## Usage

1. Start the Flask application:

   ```shell
   flask run
   ```

2. The API will be available at `http://localhost:5000/`

## API Endpoints

- `GET /books` - Get all books
- `GET /books/<id>` - Get a specific book
- `POST /books` - Add a new book
- `PUT /books/<id>` - Update a book
- `DELETE /books/<id>` - Delete a book

## Testing

Run tests with `pytest`:

```python
python -m pytest
```
````
<!-- markdownlint-enable MD029 -->
{{< /tab >}}

{{< tab title="requirements.txt" >}}

Lists all required Python packages with versions.

```plaintext
Flask==2.2.3
pytest==7.3.1
pytest-flask==1.2.0
Flask-SQLAlchemy==3.0.3
SQLAlchemy==2.0.9
python-dotenv==1.0.0
Werkzeug==2.2.3
requests==2.28.2
```

{{< /tab >}}

{{< tab title="setup.py" >}}

Project configuration for packaging.

```python
from setuptools import setup, find_packages

setup(
    name="bookstore-inventory",
    version="0.1.0",
    packages=find_packages(),
    include_package_data=True,
    install_requires=[
        "Flask>=2.2.0",
        "Flask-SQLAlchemy>=3.0.0",
        "SQLAlchemy>=2.0.0",
        "pytest>=7.0.0",
        "pytest-flask>=1.2.0",
        "python-dotenv>=1.0.0",
    ],
    python_requires=">=3.8",
    author="Your Name",
    author_email="your.email@example.com",
    description="A Flask web application for managing bookstore inventory",
    keywords="flask, inventory, bookstore",
    url="https://gitlab.com/your-username/python-shop-app",
    classifiers=[
        "Development Status :: 3 - Alpha",
        "Environment :: Web Environment",
        "Framework :: Flask",
        "Intended Audience :: Developers",
        "License :: OSI Approved :: MIT License",
        "Programming Language :: Python :: 3",
        "Programming Language :: Python :: 3.8",
        "Programming Language :: Python :: 3.9",
        "Programming Language :: Python :: 3.10",
    ],
)
```

{{< /tab >}}

{{< tab title=".env" >}}

Contains environment variables for the application.

```plaintext
# Flask configuration
FLASK_APP=app
FLASK_ENV=development
FLASK_DEBUG=1
SECRET_KEY=your-secret-key-change-in-production

# Database configuration
DATABASE_URL=sqlite:///bookstore.db
TEST_DATABASE_URL=sqlite:///test_bookstore.db

# Application settings
BOOK_TITLE_MAX_LENGTH=100
MAX_PRICE=1000.00
MAX_QUANTITY=1000
```

{{< /tab >}}

{{< tab title="app/models/article.py" >}}

Article class with full validation.

```python
class Article:
    """Article class for a bookstore inventory system."""

    def __init__(self, name, price, quantity, article_id=None):
        """
        Initialize an article with validation.

        Args:
            name (str): The name/title of the book
            price (float): The price of the book
            quantity (int): The quantity in stock
            article_id (int, optional): The unique identifier for the article

        Raises:
            ValueError: If any of the fields fail validation
        """
        self.id = article_id
        self.set_name(name)
        self.set_price(price)
        self.set_quantity(quantity)

    def set_name(self, name):
        """
        Set the name with validation.

        Args:
            name (str): The name/title of the book

        Raises:
            ValueError: If name is empty or too long
        """
        if not name or not isinstance(name, str):
            raise ValueError("Book title cannot be empty and must be a string")

        if len(name) > 100:  # Max length validation
            raise ValueError("Book title cannot exceed 100 characters")

        self.name = name.strip()

    def set_price(self, price):
        """
        Set the price with validation.

        Args:
            price (float): The price of the book

        Raises:
            ValueError: If price is negative or not a number
        """
        try:
            price_float = float(price)
        except (ValueError, TypeError):
            raise ValueError("Price must be a number")

        if price_float < 0:
            raise ValueError("Price cannot be negative")

        if price_float > 1000:  # Max price validation
            raise ValueError("Price cannot exceed 1000")

        # Ensure price has at most 2 decimal places
        self.price = round(price_float, 2)

    def set_quantity(self, quantity):
        """
        Set the quantity with validation.

        Args:
            quantity (int): The quantity in stock

        Raises:
            ValueError: If quantity is negative or not an integer
        """
        try:
            quantity_int = int(quantity)
        except (ValueError, TypeError):
            raise ValueError("Quantity must be an integer")

        if quantity_int < 0:
            raise ValueError("Quantity cannot be negative")

        if quantity_int > 1000:  # Max quantity validation
            raise ValueError("Quantity cannot exceed 1000")

        self.quantity = quantity_int

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
        return cls(
            name=data["name"],
            price=data["price"],
            quantity=data["quantity"],
            article_id=article_id
        )
```

{{< /tab >}}

{{< tab title="app/routes/shop.py" >}}

Complete API endpoints with error handling.

```python
from flask import Blueprint, request, jsonify, current_app
from app.models.article import Article
from app import database
import logging

# Create a blueprint for the shop routes
shop_bp = Blueprint('shop', __name__, url_prefix='/books')

# Set up logging
logger = logging.getLogger(__name__)

@shop_bp.route('', methods=['GET'])
def get_all_books():
    """Get all books from the inventory."""
    try:
        books = database.get_all_articles()
        return jsonify([book.to_dict() for book in books]), 200
    except Exception as e:
        logger.error(f"Error getting all books: {str(e)}")
        return jsonify({"error": "Failed to retrieve books"}), 500

@shop_bp.route('/<int:book_id>', methods=['GET'])
def get_book(book_id):
    """Get a specific book by ID."""
    try:
        book = database.get_article_by_id(book_id)
        if book:
            return jsonify(book.to_dict()), 200
        return jsonify({"error": f"Book with ID {book_id} not found"}), 404
    except Exception as e:
        logger.error(f"Error getting book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to retrieve book {book_id}"}), 500

@shop_bp.route('', methods=['POST'])
def add_book():
    """Add a new book to the inventory."""
    data = request.get_json()

    if not data:
        return jsonify({"error": "No data provided"}), 400

    required_fields = ['name', 'price', 'quantity']
    for field in required_fields:
        if field not in data:
            return jsonify({"error": f"Missing required field: {field}"}), 400

    try:
        # Validate data by creating an Article object
        new_book = Article(
            name=data['name'],
            price=data['price'],
            quantity=data['quantity']
        )

        # Save to database
        book_id = database.add_article(new_book)

        # Return the created book
        created_book = database.get_article_by_id(book_id)
        return jsonify(created_book.to_dict()), 201

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error adding book: {str(e)}")
        return jsonify({"error": "Failed to add book"}), 500

@shop_bp.route('/<int:book_id>', methods=['PUT'])
def update_book(book_id):
    """Update an existing book."""
    data = request.get_json()

    if not data:
        return jsonify({"error": "No data provided"}), 400

    try:
        # Check if book exists
        existing_book = database.get_article_by_id(book_id)
        if not existing_book:
            return jsonify({"error": f"Book with ID {book_id} not found"}), 404

        # Update book properties
        if 'name' in data:
            existing_book.set_name(data['name'])
        if 'price' in data:
            existing_book.set_price(data['price'])
        if 'quantity' in data:
            existing_book.set_quantity(data['quantity'])

        # Save updated book
        database.update_article(existing_book)

        # Return the updated book
        updated_book = database.get_article_by_id(book_id)
        return jsonify(updated_book.to_dict()), 200

    except ValueError as e:
        return jsonify({"error": str(e)}), 400
    except Exception as e:
        logger.error(f"Error updating book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to update book {book_id}"}), 500

@shop_bp.route('/<int:book_id>', methods=['DELETE'])
def delete_book(book_id):
    """Delete a book from the inventory."""
    try:
        # Check if book exists
        existing_book = database.get_article_by_id(book_id)
        if not existing_book:
            return jsonify({"error": f"Book with ID {book_id} not found"}), 404

        # Delete the book
        database.delete_article(book_id)

        return jsonify({"message": f"Book with ID {book_id} deleted successfully"}), 200

    except Exception as e:
        logger.error(f"Error deleting book {book_id}: {str(e)}")
        return jsonify({"error": f"Failed to delete book {book_id}"}), 500
```

{{< /tab >}}

{{< tab title="app/database.py" >}}

Database operations with connection management.

```python
import sqlite3
import os
import logging
from contextlib import contextmanager
from app.models.article import Article

# Set up logging
logger = logging.getLogger(__name__)

# Get database path from environment variable or use default
DATABASE_PATH = os.environ.get('DATABASE_PATH', 'bookstore.db')

@contextmanager
def get_db_connection():
    """
    Context manager for database connections.
    Automatically handles connection opening, committing, and closing.

    Yields:
        sqlite3.Connection: Database connection object
    """
    conn = None
    try:
        conn = sqlite3.connect(DATABASE_PATH)
        # Configure connection to return rows as dictionaries
        conn.row_factory = sqlite3.Row
        yield conn
        conn.commit()
    except sqlite3.Error as e:
        if conn:
            conn.rollback()
        logger.error(f"Database error: {str(e)}")
        raise
    finally:
        if conn:
            conn.close()

def initialize_database():
    """
    Initialize the database by creating the articles table if it doesn't exist.
    """
    try:
        with get_db_connection() as conn:
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

            logger.info("Database initialized successfully")
    except sqlite3.Error as e:
        logger.error(f"Failed to initialize database: {str(e)}")
        raise

def add_article(article):
    """
    Add a new article to the database.

    Args:
        article (Article): Article object to add

    Returns:
        int: ID of the newly added article
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                "INSERT INTO articles (name, price, quantity) VALUES (?, ?, ?)",
                (article.name, article.price, article.quantity)
            )

            # Get the ID of the newly inserted article
            article_id = cursor.lastrowid
            logger.info(f"Added article with ID {article_id}")
            return article_id
    except sqlite3.Error as e:
        logger.error(f"Failed to add article: {str(e)}")
        raise

def get_article_by_id(article_id):
    """
    Get an article by its ID.

    Args:
        article_id (int): ID of the article to retrieve

    Returns:
        Article: Article object if found, None otherwise
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("SELECT * FROM articles WHERE id = ?", (article_id,))
            row = cursor.fetchone()

            if row:
                return Article(
                    name=row['name'],
                    price=row['price'],
                    quantity=row['quantity'],
                    article_id=row['id']
                )
            return None
    except sqlite3.Error as e:
        logger.error(f"Failed to get article {article_id}: {str(e)}")
        raise

def get_all_articles():
    """
    Get all articles from the database.

    Returns:
        list: List of Article objects
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("SELECT * FROM articles")
            rows = cursor.fetchall()

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
    except sqlite3.Error as e:
        logger.error(f"Failed to get all articles: {str(e)}")
        raise

def update_article(article):
    """
    Update an existing article in the database.

    Args:
        article (Article): Article object with updated values

    Returns:
        bool: True if successful, False if article not found
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute(
                "UPDATE articles SET name = ?, price = ?, quantity = ? WHERE id = ?",
                (article.name, article.price, article.quantity, article.id)
            )

            # Check if an article was actually updated
            if cursor.rowcount == 0:
                logger.warning(f"No article found with ID {article.id}")
                return False

            logger.info(f"Updated article with ID {article.id}")
            return True
    except sqlite3.Error as e:
        logger.error(f"Failed to update article {article.id}: {str(e)}")
        raise

def delete_article(article_id):
    """
    Delete an article from the database.

    Args:
        article_id (int): ID of the article to delete

    Returns:
        bool: True if successful, False if article not found
    """
    try:
        with get_db_connection() as conn:
            cursor = conn.cursor()

            cursor.execute("DELETE FROM articles WHERE id = ?", (article_id,))

            # Check if an article was actually deleted
            if cursor.rowcount == 0:
                logger.warning(f"No article found with ID {article_id}")
                return False

            logger.info(f"Deleted article with ID {article_id}")
            return True
    except sqlite3.Error as e:
        logger.error(f"Failed to delete article {article_id}: {str(e)}")
        raise
```

{{< /tab >}}
<!-- markdownlint-disable -->
{{< tab title="app/__init__.py" >}}
<!-- markdownlint-enable -->
Flask application factory.

```python
import os
from flask import Flask
from dotenv import load_dotenv

def create_app(test_config=None):
    """
    Application factory for creating the Flask app.

    Args:
        test_config (dict, optional): Test configuration to override default config

    Returns:
        Flask: Configured Flask application
    """
    # Load environment variables from .env file
    load_dotenv()

    # Create and configure the app
    app = Flask(__name__, instance_relative_config=True)

    # Set default configuration
    app.config.from_mapping(
        SECRET_KEY=os.environ.get('SECRET_KEY', 'dev'),
        DATABASE_PATH=os.environ.get('DATABASE_URL', 'bookstore.db'),
        BOOK_TITLE_MAX_LENGTH=int(os.environ.get('BOOK_TITLE_MAX_LENGTH', 100)),
        MAX_PRICE=float(os.environ.get('MAX_PRICE', 1000.00)),
        MAX_QUANTITY=int(os.environ.get('MAX_QUANTITY', 1000))
    )

    # Override config with test config if provided
    if test_config:
        app.config.update(test_config)

    # Ensure the instance folder exists
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
            "endpoints": {
                "books": "/books",
                "book_by_id": "/books/<id>"
            }
        }

    return app
```

{{< /tab >}}

{{< /tabs >}}

1. Check your code files against these examples.

1. To verify if your code works, ask Chat how to start a local application server:

   ```plaintext
   How do I start a local application server for my Python web application?
   ```

1. Follow the instructions, and check if your application is working.

If your application is working, congratulations! You have successfully used
GitLab Duo Chat and Code Suggestions to build working online shop application.

If it is not working, then you need to find out why. Chat and Code Suggestions
can help you create tests to ensure your application works as expected and
identify any issues that need to be fixed.
[Issue 1284](https://gitlab.com/gitlab-org/technical-writing/team-tasks/-/issues/1284)
exists to create this tutorial.

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
