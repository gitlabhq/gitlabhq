package gitlab.scope

applicable := [result.policy | some result in results; result.applies]

not_applicable := [result.policy | some result in results; not result.applies]

applicability := {
	"applicable": applicable,
	"not_applicable": not_applicable,
	"results": [result | some result in results],
}

# policy "Applies everywhere"
results contains {
	"policy": "Applies everywhere",
	"applies": true,
	"reason": "no policy_scope: applies to all projects",
}
