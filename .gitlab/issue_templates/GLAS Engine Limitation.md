<!---
This template facilitates communication between VR and SAST team regarding GLAS engine improvements.
Use this to raise cases where the GLAS engine's behavior does not align with the SAST rule.
--->

### Problem
<!-- Describe the limitation in the GLAS engine:
- What capability is missing
- Security impact (false positives/negatives) -->

### Steps to reproduce
<!-- Provide:
1. Code example that demonstrates the limitation
1. Rule that exposes the limitation (ID/pattern)
1. Expected vs actual behavior
1. Semgrep playground link (if applicable) -->

### Other references
<!-- Include relevant links such as:
- Rule MR with failing test
- GLAS pipeline with failing job
- GLAS results JSON file -->

### SAST Reaction rotation engineer todo
@gitlab-org/secure/static-analysis/reaction-rotation

See [SAST Reaction rotation GLAS limitations](https://handbook.gitlab.com/handbook/engineering/development/sec/secure/static-analysis/reaction_rotation/#glas-limitations-issues) to traige this issue.

/label ~"section::sec" ~"devops::application security testing" ~"group::static analysis" ~"Category:SAST" ~"GLAS::VR-Reported" ~"GLAS::EngineLimitation"
