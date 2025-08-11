This directory contains files that act as overrides based on conditions.

Gitlab CI natively merges definitions with same key names. Because GitLab CI doesn't support templating with conditionals natively, such overrides can be used together with rule based `include` directives to alter certain definitions based on particular conditions defined as rules.
