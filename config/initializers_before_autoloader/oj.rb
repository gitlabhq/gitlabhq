# frozen_string_literal: true

# Ensure Oj runs in json-gem compatibility mode by default
Oj.default_options = { mode: :rails }
