package governance

# rule 0: setting_validation

violation contains {"msg": msg, "details": {"rule_index": 0, "path": "project.settings.visibility", "expected": "private", "actual": setting_actual_0}} if {
	setting_actual_0 := object.get(input, ["project", "settings", "visibility"], null)
	setting_actual_0 != null
	setting_actual_0 != "private"
	msg := sprintf("setting %s must be %v", ["visibility", "private"])
}
