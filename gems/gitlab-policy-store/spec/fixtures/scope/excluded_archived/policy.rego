package gitlab.scope

import rego.v1

applicable := [result.policy | some result in results; result.applies]

not_applicable := [result.policy | some result in results; not result.applies]

applicability := {
	"applicable": applicable,
	"not_applicable": not_applicable,
	"results": [result | some result in results],
}

# policy "Excluding archived projects"

default scope_excluded := false

scope_excluded if {
	input.project.archived == true
}

default scope_included := false

scope_included if { true }

default scope_applies := false

scope_applies if {
	not scope_excluded
	scope_included
}

results contains {
	"policy": "Excluding archived projects",
	"applies": scope_applies,
	"reason": sprintf("excluded=%v, included=%v (match_mode=all)", [scope_excluded, scope_included]),
}
