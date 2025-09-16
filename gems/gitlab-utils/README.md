# Gitlab::Utils

This Gem contains all code that is not dependent on application code
or business logic and provides a generic functions like:

- safe parsing of YAML
- version comparisions
- `strong_memoize`
- uuid_v7 till we have min ruby >= 3.3.0
- **Security Note**: UUID v7 provides 74 bits of entropy (vs UUID v4's 122 bits) and exposes 
creation timestamps. Do not use for authentication tokens or security-critical identifiers.
Use for database primary keys and non-sensitive identifiers only.
