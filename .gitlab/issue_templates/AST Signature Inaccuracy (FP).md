<!---
Please read this!

Before opening a new issue, make sure to search for keywords in the issues
filtered by the "AST::Ruleset::FP" label:

- https://gitlab.com/gitlab-org/gitlab/-/issues/?sort=updated_desc&state=opened&label_name%5B%5D=AST%3A%3ARuleset%3A%3AFP&first_page_size=100

and verify the issue you're about to submit isn't a duplicate.

Please verify that the issue template corresponds to the problem you're facing.
- False Positive - a finding that was wrongly flagged as a vulnerability
- False Negative - a valid vulnerability that wasn't flagged by the engine
--->

### Summary

<!---
Summarize the inaccuracy encountered concisely.
Correctly classify the category, e.g.: 
 /label ~Category:SAST
 /label ~Category:Secret Detection
 /label ~Category:Dynamic Analysis
--->

### Steps to reproduce

<!-- Describe how one can reproduce the issue - this is very important. Please use an ordered list. -->

### Example Project / Code Snippets

<!-- If possible, please create an example project here on GitLab.com that exhibits the problematic 
behavior, and link to it here. 

For SAST, please include all information for both source and sink if possible.
For Secret Detection, please include an example of a secret, examples of invalid secrets, etc. 
(Please make sure to not post valid working secrets here)
--->

### What is the current *inaccurate* behavior?

<!-- Describe what actually happens. -->

### What is the expected *correct* behavior?

<!-- Describe what you should see instead. -->

### Relevant logs and/or screenshots

<!-- Paste any relevant logs - please use code blocks (```) to format console output, logs, and code
 as it's tough to read otherwise. -->

/label ~"group::vulnerability research"
/label ~"AST::Ruleset::FP"
/label ~"type::maintenance"
/label ~"workflow::refinement"
/milestone %Backlog
/confidential