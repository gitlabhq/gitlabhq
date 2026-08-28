package governance

# rule 2: calendar

violation contains {"msg": msg, "details": {"rule_index": 2, "window": freeze_window.name}} if {
	freeze_window := [
		{"name": "summit", "tiers": ["production", "staging"], "starts_at": "2026-09-01T10:00:00Z", "ends_at": "2026-09-03T00:00:00Z"},
		{"name": "eoq-freeze", "tiers": ["production"], "starts_at": "2026-12-24T00:00:00Z", "ends_at": "2027-01-02T00:00:00Z"},
	][_]
	input.environment.tier in freeze_window.tiers
	input.evaluated_at >= freeze_window.starts_at
	input.evaluated_at < freeze_window.ends_at
	msg := sprintf("deployment blocked by freeze window %s (%s to %s)", [freeze_window.name, freeze_window.starts_at, freeze_window.ends_at])
}
