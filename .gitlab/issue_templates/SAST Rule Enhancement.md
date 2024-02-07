<!-- 

This issue template is sourced from https://gitlab.com/gitlab-org/gitlab/-/blob/master/.gitlab/issue_templates/SAST%20Ruleset%20Enhancement.md and is maintained by the Secure: Vulnerability Research team (https://handbook.gitlab.com/handbook/engineering/development/sec/secure/vulnerability-research/), most of its content is based on the documentation found in the GitLab SAST Rules Project under https://gitlab.com/gitlab-org/security-products/sast-rules/-/blob/main/docs.

-->

## Background and Rationale behind this Work

<!--
REPLACE: As per https://gitlab.com/gitlab-org/gitlab/-/issues/425704 and https://gitlab.com/gitlab-org/gitlab/-/issues/425704 we are continuously working towards improving the coverage and efficacy of our SAST rules.
-->

### Desired Change 

<!--
REPLACE: This issue is aimed at creating, embedding, or enhancing a GitLab SAST rule that detects the issue seen in https://foo.example.com and https://bar.example.com
-->

---

## Implementation Plan

### Assessment 


#### If Creating a New Rule

- [ ] Determine whether the rule in question currently exists or ever existed in our [GitLab SAST Rules](https://gitlab.com/gitlab-org/security-products/sast-rules).
- [ ] If it existed but was removed or merged into another rule, e.g. due to generating a high number of false positives, document said context in the comments and work to avoid the same problems with this new rule.


#### If Embedding or Adapting an External Rule

Determine whether the test code or minimal runnable example (MRE) accompanying the rule to be embedded or adapted:

- [ ] Is realistic in its portrayal of the problem, e.g. test code for a Django rule crammed within a single Python file and containing no views or models isn't realistic.
- [ ] Contains a sufficient number of true positive(TP) testcases(`# ruleid: my-rule`) and variations. In the case of Python, for example, rules and tests considering `foo("bar")` but not for `foo(f"{bar}")` nor `foo("%s" % bar)` are most likely insufficient.
- [ ] Contains a sufficient number of true negative(TN) testcases(`# okruleid: my-rule`) and variations.

- [ ] Determine whether [the GitLab SAST ruleset](https://gitlab.com/gitlab-org/security-products/sast-rules) detects instances of the vulnerability in the acompanying MRE and if there is room for improvement regarding when compared to the external rule (e.g. `semgrep --test --config sast-rules/gitlab-rule.yml mre/` vs `semgrep --test --config external-rule.yml mre/` ).

#### If Enhancing an already Exisiting Rule

Proceed to the next section.

#### Classification

- [ ] In order to keep track of the ruleset evolution and also maintain proper licensing, classify the work in this issue and justify your decision: 

If a new rule will be created from scratch due to poor performance of externally sourced rules, label this issue as ~"SAST::Ruleset::Addition"

If an existing rule will be enhanced, label this issue as ~"SAST::Ruleset::Enhancement"

If an equivalent rule doesn't exist already but embedding its externally sourced counterpart(s) improves our SAST Ruleset, label this issue as ~"SAST::Ruleset::Inclusion"

If an equivalent rule exists already but can be improved based on external rules, label this issue as ~"SAST::Ruleset::Adaptation"

If the addition, inclusion or adaptation of a rule addressing the Desired Change in this issue adds no value to our SAST Ruleset, label this issue as ~"SAST::Ruleset::Skip" 

### Preparation

:information_source: Think out loud as well as document your research and design decisions; feel free to do so at the end of this issue description or in individual comments. 

- [ ] No matter if you are creating or embedding a new [GitLab SAST Rule](https://gitlab.com/gitlab-org/security-products/sast-rules) or enhancing and adapting an already existing one, continuously refer to repositories with appropriate licensing schemes such as [Semgrep Community](https://github.com/semgrep/semgrep-rules/), [PyCQA Bandit](https://github.com/PyCQA/bandit/), and others that focus on similar issues to draw inspiration from them.
- [ ] Learn about and document the purpose as well as effectiveness of the rules you found and their accompanying sample code by looking at the test performance (using `semgrep --test` and `semgrep scan --config rule.yml code/`). Include this information as references and code snippets in the rule's implementation issue (for example, https://gitlab.com/gitlab-org/gitlab/-/issues/434269)
- [ ] Research and understand thoroughly the nature of the vulnerability to be detected, for example why, when, how it arises and why, when, how it doesn't.
- [ ] Use the code search function on Gitlab, Github and other platforms to find realistic usage scenarios of the vulnerable patterns:
- https://github.com/search?q=language%3APython+path%3A*.py+%3DRawSQL&type=code
- https://https://grep.app/search?q=%3DRawSQL%28
- https://gitlab.com/search?group_id=2504721&scope=blobs&search=eval%5C%28).
- https://www.tabnine.com/code/java/methods/java.sql.PreparedStatement/executeQuery
- https://cs.opensource.google/search?q=language:python%20%20pcre:yes%09os.system
- [ ] AI can save time by rephrasing rule descriptions and generating test cases, but should not be relied upon for the actual security research work and evaluation. To align with our [dogfooding](https://handbook.gitlab.com/handbook/values/#dogfooding) value, please use GitLab Duo, which is powered by best-in-class AI models.
- [ ] Document the scenarios and variants of the security problem you are looking to detect in this issue, either in its description or as comments, and prioritize them from most realistic and common to less realistic and unlikely.
- [ ] If the rule does not currently exist in our [GitLab SAST Rules](https://gitlab.com/gitlab-org/security-products/sast-rules), use the publicly available rules and code examples found previously as inspiration, making use of them when their license allows us to do so. Be skeptical about their quality and improve on them when necessary.

### Implementation

- [ ] Create a simple but realistic Minimal Runnable Example (MRE), in e.g. `mre/`, which captures, initially, the most representative variant of the problem to be addressed by the rule. 
- [ ] Create a Semgrep rule, e.g. `my-rule.yml`, that correctly identifies the vulnerabilities present in your `mre/` so far and place it in the language, framework and variant folder most suited for it, e.g. `python/django/security/injection/sql`.
- [ ] For each instance of the problem to be detected (`# ruleid: my-rule`) or to be ignored (`# okruleid: my-rule`) within your MRE, add two comments above each occurrence:
```
# rationale: <description of the vulnerability or variant>
# ruleid: <java_some_rule_id>
```
  - [ ] One comment should explain the rationale behind the scenario and test-case, its pitfalls and anything you deem relevant, e.g. `# this test case is necessary because string interpolations are handled in a different manner when compared to normal string literals`
  - [ ] The second comment should follow Semgrep's [rule testing guidelines](https://semgrep.dev/docs/writing-rules/testing-rules/), making it clear whether the line immediately following said comment represents a true positive ( `# ruleid: my-rule` ), a true negative ( `# ok: my-rule` ) or a false negative to be addressed in the future (`# todoruleid: my-rule`)
- [] Enhance and extend your MRE as well as its associated rule with other important variants and corner cases of the same problem according to your prioritized list of scenarios. Make sure to add variations which are syntactically and semantically different enough to warrant doing so and which make both your rule and MRE more robust.
- [ ] Continuously test your rule on your MRE ( `semgrep scan --config my-rule.yml mre/` ) and update it as your MRE becomes more complex while also continuing to add comments and Semgrep test annotations to help verifying the desired coverage.
- [ ] Once you are satisfied with the level of detail in your MRE as well as the coverage of your rule and its test results, distill your  `mre/` into a unit test file(e.g. `rule.py`) or series of files (`test/rule.py`) with the most representative test cases and place them into the same folder as your rule within the `sast-rules` project.

#### Merge the MRE

- [ ] Clone our [Real World Test Projects](https://gitlab.com/gitlab-org/security-products/tests/sast-rules-apps/) and extend it with your MRE demonstrating the problem. Alternatively, discuss the creation of a new folder or repository if none fits.
- [ ] Push the changes to [gitlab-org/security-products/tests/sast-rules-apps](https://gitlab.com/gitlab-org/security-products/tests/sast-rules-apps/) as a feature branch if you have access; otherwise push it to a personal fork of the project
- [ ] Create a new MR and mention this issue in it so they are linked.
- [ ] A member of the `@gitlab-org/secure/vulnerability-research` team will assign themselves as reviewer shortly, work with them to finalise and merge your work.


#### Merge the Rule 

- [ ] Push the changes to `sast-rules` as a feature branch to [gitlab-org/security-products/sast-rules](https://gitlab.com/gitlab-org/security-products/sast-rules/) if you have access; otherwise push it to a personal fork of the project.
- [ ] Create the MR and mention this issue in it so they are linked.
- [ ] A member of the `@gitlab-org/secure/vulnerability-research` team will assign themselves as reviewer shortly, work with them to finalise and merge your work.
- [ ] Find the [latest sast-rules release MR](https://gitlab.com/gitlab-org/security-products/sast-rules/-/merge_requests?scope=all&state=opened&search=draft%3A+Release) and add a line to CHANGELOG.md detailing briefly the changes performed, their intent and the MR ID where this work was done.

```
## v2.X.X
- Adds/Changes/Updates new pattern to existing rule `java/xss/rule-XXX.yml` for Java that checks XXX for XXX (!<merge request id>) 
...

```

## Workflow 

Use the [SAST Improvement Board](https://gitlab.com/groups/gitlab-org/-/boards/7309853) to track the progress of your issues or find other SAST work to get involved with.

Use the ~"workflow::ready for development", ~"workflow::in dev" and ~"workflow::ready for review" labels to signal, respectively, that this issue is ready to be worked on, this issue is actively being worked on by the assignee or this issue and its associated MR require review before proceeding.

/label ~"devops::secure" ~"feature::enhancement" ~"group::vulnerability research" ~"section::sec" ~"type::feature" ~"Category:SAST" ~"SAST::Ruleset" 

/epic &10971

---

### Research and other Considerations


#### TODO

#### TODO

#### References

1. 
1. 
1. 
1. 
1. 
