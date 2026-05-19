### API Documentation Format

- Every method must include the REST API request with HTTP method (GET, PUT, DELETE) followed by the request path starting with `/`
- Every method must have a detailed description of attributes in a table format, with required attributes listed first, then sorted alphabetically
- Every method must include a cURL example using `https://gitlab.example.com/api/v4/` as the endpoint and `<your_access_token>` as the token placeholder
- Every method must have a detailed description of the response body and a JSON response example
- If endpoint attributes are available only to higher subscription tiers or specific offerings, include this information in the attribute description
- For complex object types, represent sub-attributes with dots, like `project.name` or `projects[].name` for arrays
- For cURL commands: use long option names (`--header` instead of `-H`), declare URLs with the `--url` parameter in double quotes, and use line breaks with `\` for readability
