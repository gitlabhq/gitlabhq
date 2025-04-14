---
stage: none
group: unassigned
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
title: Create a new python projects
---

When creating a new Python repository, some guidelines help keep our code standardized.

## Recommended libraries

### Development & testing

- [`pytest`](https://docs.pytest.org/): Primary testing framework for writing and running tests.
- [`pytest-cov`](https://pytest-cov.readthedocs.io/): Test coverage reporting plugin for `pytest`.
- [`black`](https://black.readthedocs.io/): Opinionated code formatter that ensures consistent code
  style.
- [`flake8`](https://flake8.pycqa.org/): Linter for style enforcement.
- [`pylint`](https://pylint.pycqa.org/): Comprehensive linter for error detection and quality
  enforcement.
- [`mypy`](https://mypy.readthedocs.io/): Static type checker.
- [`isort`](https://pycqa.github.io/isort/): Utility to sort imports.

### Package manager & build system

- [`poetry`](https://python-poetry.org/): Modern packaging and dependency management.

### Common utilities

- [`typer`](https://typer.tiangolo.com/): Library for building CLI applications.
- [`python-dotenv`](https://saurabh-kumar.com/python-dotenv/): Environment variable management.
- [`pydantic`](https://docs.pydantic.dev/latest/): Data validation and settings management using
  Python type annotations.
- [`fastapi`](https://fastapi.tiangolo.com): Modern, high-performance web framework for building
  APIs.
- [`structlog`](https://www.structlog.org/): Structured logging library.
- [`httpx`](https://docs.pydantic.dev/latest/): Asynchronous and performant HTTP client.
- [`rich`](https://rich.readthedocs.io/en/latest/): Terminal formatting library for rich text.
- [`sqlmodel`](https://sqlmodel.tiangolo.com/): Intuitive and robust ORM.
- [`tqdm`](https://github.com/tqdm/tqdm): Fast, extensible progress bar for CLI.

## Recommended folder structure

Depending on the type of project, for example, API service, CLI application or library, the folder
structure can be varied. The following structure is for a standard CLI application.

```plaintext
project_name/
├── .gitlab/                     # GitLab-specific configuration
│   ├── issue_templates/         # Issue templates
│   └── merge_request_templates/ # MR templates
├── .gitlab-ci.yml               # CI/CD configuration
├── project_name/                # Main package directory
│   ├── __init__.py              # Package initialization
│   ├── cli.py                   # Command-line interface entry points
│   ├── config.py                # Configuration handling
│   └── core/                    # Core functionality
│       └── __init__.py
├── tests/                       # Test directory
│   ├── __init__.py
│   ├── conftest.py              # pytest fixtures and configuration
│   └── test_*.py                # Test modules
├── docs/                        # Documentation
├── scripts/                     # Utility scripts
├── README.md                    # Project overview
├── CONTRIBUTING.md              # Contribution guidelines
├── LICENSE                      # License information
├── pyproject.toml               # Project metadata and dependencies (Poetry)
```

## Linter configuration

We should consolidate configurations into `pyproject.toml` as much as possible.

### `pyproject.toml`

```toml
[tool.black]
line-length = 120

[tool.isort]
profile = "black"

[tool.mypy]
python_version = 3.12
ignore_missing_imports = true

[tool.pylint.main]
jobs = 0
load-plugins = [
  # custom plugins
]

[tool.pylint.messages_control]
enable = [
  # custom plugins
]

[tool.pylint.reports]
score = "no"
```

### `setup.cfg`

```ini
[flake8]
extend-ignore = E203,E501
extend-exclude = **/__init__.py,.venv,tests
indent-size = 4
max-line-length = 120
```

## Example Makefile

```makefile
# Excerpt from project Makefile showing common targets

# lint
.PHONY: install-lint-deps
install-lint-deps:
    @echo "Installing lint dependencies..."
    @poetry install --only lint

.PHONY: format
format: black isort

.PHONY: black
black: install-lint-deps
    @echo "Running black format..."
    @poetry run black ${CI_PROJECT_DIR}

.PHONY: isort
isort: install-lint-deps
    @echo "Running isort format..."
    @poetry run isort ${CI_PROJECT_DIR}

.PHONY: lint
lint: flake8 check-black check-isort check-pylint check-mypy

.PHONY: flake8
flake8: install-lint-deps
    @echo "Running flake8..."
    @poetry run flake8 ${CI_PROJECT_DIR}

.PHONY: check-black
check-black: install-lint-deps
    @echo "Running black check..."
    @poetry run black --check ${CI_PROJECT_DIR}

.PHONY: check-isort
check-isort: install-lint-deps
    @echo "Running isort check..."
    @poetry run isort --check-only ${CI_PROJECT_DIR}

.PHONY: check-pylint
check-pylint: install-lint-deps install-test-deps
    @echo "Running pylint check..."
    @poetry run pylint ${CI_PROJECT_DIR}

.PHONY: check-mypy
check-mypy: install-lint-deps
    @echo "Running mypy check..."
    @poetry run mypy ${CI_PROJECT_DIR}

# test
.PHONY: test
test: install-test-deps
    @echo "Running tests..."
    @poetry run pytest

.PHONY: test-coverage
test-coverage: install-test-deps
    @echo "Running tests with coverage..."
    @poetry run pytest --cov=duo_workflow_service --cov=lints --cov-report term --cov-report html
```

## Example GitLab CI Configuration

```yaml
# Excerpt from .gitlab-ci.yml showing linting and testing jobs

image: python:3.13

stages:
  - lint
  - test

variables:
  PIP_CACHE_DIR: "$CI_PROJECT_DIR/.cache/pip"
  POETRY_CACHE_DIR: "$CI_PROJECT_DIR/.cache/poetry"
  POETRY_VERSION: "2.1.2"

cache:
  key: ${CI_COMMIT_REF_SLUG}
  paths:
    - $PIP_CACHE_DIR
    - $POETRY_CACHE_DIR
    - .venv/

# Base template for Python jobs
.poetry:
  before_script:
    - pip install poetry==${POETRY_VERSION}
    - poetry config virtualenvs.in-project true
    - poetry add --dev black isort flake8 pylint mypy pytest pytest-cov

# Linting jobs
black:
  extends: .poetry
  stage: lint
  script:
    - poetry run black --check ${CI_PROJECT_DIR}

isort:
  extends: .poetry
  stage: lint
  script:
    - poetry run isort --check-only ${CI_PROJECT_DIR}

flake8:
  extends: .poetry
  stage: lint
  script:
    - poetry run flake8 ${CI_PROJECT_DIR}

pylint:
  extends: .poetry
  stage: lint
  script:
    - poetry run pylint ${CI_PROJECT_DIR}

mypy:
  extends: .poetry
  stage: lint
  script:
    - poetry run mypy ${CI_PROJECT_DIR}

# Testing jobs
test:
  extends: .poetry
  stage: test
  script:
    - poetry run pytest --cov=duo_workflow_service --cov-report=term --cov-report=xml:coverage.xml --junitxml=junit.xml
  coverage: '/TOTAL.+?(\d+\%)/'
  artifacts:
    when: always
    reports:
      junit: junit.xml
      coverage_report:
        coverage_format: cobertura
        path: coverage.xml
```

## Adding reviewer roulette

We recommend reviewer roulette to distribute review workload across reviewers and maintainers. A pool of Python Reviewers is available 
for small Python projects and can be configured following [these steps](maintainership.md#how-to-set-up-a-python-code-review-process).

To create a pool of reviewers specific to a project:

1. Follow the
   [GitLab Dangerfiles instructions](https://gitlab.com/gitlab-org/ruby/gems/gitlab-dangerfiles/-/blob/master/README.md#simple_roulette)
   to add the configuration to your project.

1. Implement the
   [Danger Reviewer component](https://gitlab.com/gitlab-org/components/danger-review#example) in
   your GitLab CI pipeline to automatically trigger the roulette.
