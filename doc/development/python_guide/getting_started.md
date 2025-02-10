---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Getting Started with Python in GitLab
---

## Onboarding Guide

This guide helps non-Python developers get started with Python quickly and efficiently.

1. **Set up Python**:
   - Install Python from the official [Python website](https://www.python.org/downloads/).
   - Python can also be installed with [Mise](https://mise.jdx.dev/lang/python.html):

       ```shell
       mise use python@3.14
       ```

   - Please note that while macOS comes with Python pre-installed, it's strongly advised to install and use a separate version of Python

1. **Install Poetry** for package management:
   - Poetry is a modern, Python-specific dependency manager that simplifies packaging and dependency handling. To install it, run:

     ```shell
      curl --silent --show-error --location "https://install.python-poetry.org" | python3 -
     ```

   - Make sure to ready the Poetry installation [guide](https://python-poetry.org/docs/) for full installation details

   - Once installed, create a new Python project with Poetry:

     ```shell
     poetry new my_project
     cd my_project
     poetry install
     ```

1. **Run and Debug Existing Code**
   - Familiarize yourself with the project's structure by following the `README.md`.
   - Use tools like `pdb` or IDE debugging features to debug code. Example:

     ```shell
     poetry shell
     python -m pdb <file_name>.py
     ```

   - Both [PyCharm](https://www.jetbrains.com/help/pycharm/debugging-your-first-python-application.html)
   and [VSCode](https://code.visualstudio.com/docs/python/debugging) provide great tools to debug your code

---

## Learning resources

If you are new to Python or looking to refresh your knowledge, this section provides various materials for
learning the language.

1. **[Zen of Python](https://peps.python.org/pep-0020/)**
Zen of Python - PEP 20 - is an essential read, it shapes how you think about Python and write "Pythonic" code.

1. **[Python Cheatsheet](https://www.pythoncheatsheet.org)**
A comprehensive reference covering essential Python syntax, built-in functions, and useful libraries.
This is ideal for both beginners and experienced users who want a quick, organized summary of Python's key features.

1. **[100-page Python Intro](https://learnbyexample.github.io/100_page_python_intro)**
Brief guide provides a straightforward introduction to Python, covering all the essentials needed to start programming effectively. It’s a beginner-friendly option that covers everything from syntax to debugging and testing.

1. **[Learn X in Y Minutes: Python](https://learnxinyminutes.com/docs/python)**
A very brief, high-level introduction cuts directly to the core syntax and features of Python, making it a valuable quick start for developers transitioning to Python.

1. **[Exercism Python Track](https://exercism.io/tracks/python)**
   Use Exercism's Python track as a foundation for learning Python concepts and best practices. Exercism provides hands-on practice with mentoring support, making it an excellent resource for mastering Python through coding exercises and feedback.

When building Python APIs, we use FastAPI and Pydantic. To get started with building and reviewing these technologies, refer to the following resources:

1. **[FastAPI Documentation](https://fastapi.tiangolo.com/)**
   FastAPI is a modern web framework for building APIs with Python. This resource will help you learn how to create fast and efficient web applications and APIs. FastAPI is especially useful for building Python applications with high performance and scalability.

1. **[Pydantic Documentation](https://pydantic-docs.helpmanual.io/)**
   Pydantic is a Python library for data validation and settings management using Python type annotations. Learn how to integrate Pydantic into your Python projects for easier data validation and management, particularly when working with FastAPI.

We use pytest for testing Python code. To learn more about writing and running tests with pytest, refer to the following resources:

1. **[pytest Documentation](https://docs.pytest.org/en/stable/)**
   pytest is a popular testing framework for Python that makes it easy to write simple and scalable tests. This resource provides comprehensive documentation on how to write and run tests using pytest, including fixtures, plugins, and test discovery.

1. **[Python Testing with pytest (Book)](https://pragprog.com/titles/bopytest2/python-testing-with-pytest-second-edition/)**
   This book is a comprehensive guide to testing Python code with pytest. It covers everything from the basics of writing tests to advanced topics like fixtures, plugins, and test organization.

1. **[Python Function to flowchart)](https://gitlab.com/srayner/funcgraph/)**
   This project takes any Python function and automatically creates a visual flowchart showing how the code works.

---

### Learning Group

A collaborative space for developers to study Python, FastAPI, and Pydantic, focusing on building real-world apps.

Refer to [Track and Propose Sessions for Python Learning Group](https://gitlab.com/gitlab-org/gitlab/-/issues/512600) issue for ongoing updates and discussions.

**Core Topics for Group Learning**:

1. **Basic Python Syntax**:
   - Learn Python concepts such as variables, functions, loops, and conditionals.
   - Practice at [Exercism Python Track](https://exercism.io/tracks/python).

1. **FastAPI and Pydantic**:
   - Learn how to build APIs using FastAPI and validate data with Pydantic.
   - Key resources:
     - [FastAPI Documentation](https://fastapi.tiangolo.com/)
     - [Pydantic Documentation](https://pydantic-docs.helpmanual.io/)

### Communication

- Stay updated by following the [learning group issue](<https://gitlab.com/gitlab-org/gitlab/-/issues/517449>)
- Join the discussion on Slack: **#python_getting_started**

---

### Python Review Office Hours

- **Bi-weekly sessions** for code review and discussion, led by experienced Python developers.
- These sessions are designed to help you improve your Python skills through practical feedback.
- Please feel free to add the office hours to your calendar.

---

### Encourage Recorded Group Meetings

All review and study group meetings will be recorded and shared, covering key concepts in Python, FastAPI, and Pydantic. These recordings are great for revisiting topics or catching up if you miss a session.

Add any uploaded videos to the [Python Resources](https://www.youtube.com/playlist?list=PL05JrBw4t0Kq4i9FD276WtOL1dSSm9a1G) playlist.

---

### Mentorship Process

1:1 mentorship for Python is possible and encouraged. For more information on how to get started with a mentor, please refer to the [GitLab Mentoring Handbook](https://handbook.gitlab.com/handbook/engineering/careers/mentoring/#mentoring).

---

## More learning resources

In addition to the resources already mentioned, this section provides various materials for learning the language and
it's ecosystem. In no particular order.

1. **[A Whirlwind Tour of Python (Jupyter Notebook)](https://github.com/jakevdp/WhirlwindTourOfPython)**
A fast-paced introduction to Python fundamentals, tailored especially for data science practitioners but works well for everyone who wants to get just the basic understanding of the language.
This is a Jupiter Notebook which makes this guide an interactive resource as well as a good introduction to Jupiter Notebook itself.

1. **[Python imports](https://realpython.com/absolute-vs-relative-python-imports/)**
Even for Pythonistas with a couple of projects under their belt, imports can be confusing! You’re probably reading this because you’d like to gain a deeper understanding of imports in Python, particularly absolute and relative imports.

1. **[Python -m flag](https://www.geeksforgeeks.org/what-is-the-use-of-python-m-flag/)**
   Learning the -m flag helps you run Python tools correctly by ensuring they use the right Python environment, avoiding common setup headaches.

1. **[Poetry vs pip](https://www.datacamp.com/tutorial/python-poetry)**
`virtualenv` and `pip` are built-in tool to handle project dependencies and environments. Why and when should you use
Poetry?

1. **[Python roadmap](https://roadmap.sh/python)**
Step by step guide to becoming a Python developer in 2025. Use this for inspiration and finding additional resources.

1. **[Programiz Python basics](https://programiz.pro/course/learn-python-basics)**
   Step into the world of programming with this beginner-friendly Python course and build a strong programming foundation.
