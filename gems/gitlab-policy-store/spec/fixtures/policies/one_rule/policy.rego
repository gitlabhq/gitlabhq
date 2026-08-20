package governance

# rule 0: environment

violation contains {"msg": msg, "details": {"rule_index": 0, "environment_id": input.environment.id, "environment_name": input.environment.name}} if {
	input.environment.tier in {"production"}
	msg := sprintf("deployment to %s is blocked by this policy", [input.environment.name])
}
