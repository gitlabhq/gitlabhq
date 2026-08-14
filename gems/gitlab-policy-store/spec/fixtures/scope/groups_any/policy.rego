package gitlab.scope

applicable := [result.policy | some result in results; result.applies]

not_applicable := [result.policy | some result in results; not result.applies]

applicability := {
	"applicable": applicable,
	"not_applicable": not_applicable,
	"results": [result | some result in results],
}

# policy "Scoped to groups (any)"

default scope_excluded := false

default scope_included := false

scope_included if {
	some group_id in input.groups
	group_id in {10}
}

scope_included if {
	some business_impact_id in input.security_attributes.business_impact
	business_impact_id in {1}
}

default scope_applies := false

scope_applies if {
	not scope_excluded
	scope_included
}

results contains {
	"policy": "Scoped to groups (any)",
	"applies": scope_applies,
	"reason": sprintf("excluded=%v, included=%v (match_mode=any)", [scope_excluded, scope_included]),
}
