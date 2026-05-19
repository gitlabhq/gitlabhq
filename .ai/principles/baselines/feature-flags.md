### YAML Definition

- DO NOT guess or hard-code the `milestone` value — read it from the `VERSION` file in the repo root and use the `MAJOR.MINOR` portion only (e.g., if `VERSION` contains `19.0.0-pre`, set `milestone: "19.0"`)

### Experiments

- If experiment uses only `experiment(:name, actor: current_user)` as context but the corresponding issue mentions tracking of namespace-based activation events, assignment should happen based on namespace or actor + namespace
- If experiment is first assigned during registration, there should be another assignment tracking event with namespace context: `experiment(:name, actor: current_user).track(:assignment, namespace: group)`
