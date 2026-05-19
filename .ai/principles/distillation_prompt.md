You are updating an AI code review agent's instructions based on changes
to the GitLab development documentation (the Single Source of Truth).

Below is the CURRENT agent instruction file and the UPDATED documentation
content. Your task is to produce an updated version of the agent's Checklist
section that accurately reflects ALL review guidelines from the documentation.

Rules:

1. Output ONLY the checklist content: start with "# {Title} Principles",
   then "## Checklist", then the ### subsections. Do NOT include
   "## Output Format" or any other sections after the checklist.
2. Distill concrete, checkable review rules from the documentation.
   Do not copy prose verbatim; convert to actionable checklist items.
3. Every checklist item must be traceable to the provided SSOT documentation
   or baseline rules. If a subsection or item in the CURRENT file has no
   corresponding content in the provided sources or baseline, REMOVE it.
   Do not preserve items just because they exist in the current file.
4. Maintain the existing subsection structure (### headings) where possible.
   Add new subsections for genuinely new topics.
5. Keep items concise (one line per rule where possible).
6. Do not add commentary, explanations, or meta-text outside the checklist.
7. Return the COMPLETE updated checklist (not just the diff).
8. Do NOT include any preamble, thinking, or commentary before or after the
   content. Start your response directly with the first line of the file.
9. Preserve the meaning of every existing item. Do not reorder items or
   interleave new items (append instead). You MUST rewrite every item to
   comply with rule 11 regardless of whether the SSOT changed — this is
   not optional and does not count as diff noise. Specifically:
   - Every item starting with "No " MUST become "DO NOT <verb> ..."
     (e.g., "No business logic in controllers" → "DO NOT put business logic in controllers")
   - Every item starting with "Avoid " MUST become "DO NOT <verb> ..."
     (e.g., "Avoid deep nesting" → "DO NOT nest beyond two levels")
   - Every passive or descriptive item MUST become an imperative directive
   - The rewritten item MUST be grammatically correct — "DO NOT" must be
     followed by a verb in its base form (not a noun or gerund)
    The only items exempt from rephrasing are baseline rules (rule 16),
    which must be preserved verbatim.
10. Omit rules that are universal software engineering best practices any
    experienced developer or LLM already knows (e.g., SOLID principles,
    "be kind in reviews", "use descriptive variable names"). Focus on
    GitLab-specific conventions, patterns, tooling, and gotchas that a
    reviewer would not know without reading the documentation.
11. Phrase every rule as a directive in the imperative mood. Every item must
    start with either "DO NOT <verb>" or an imperative action verb. DO NOT
    write descriptive or passive statements.
    - For anti-patterns or common mistakes: start with "DO NOT <base-form verb>"
    - For positive conventions: start with an action verb (Use, Prefer,
      Ensure, Include, Add, Set, Follow, Freeze, Pass, Wrap, etc.)
    - For descriptions of current behavior: rewrite as an instruction
    Category examples:
    a) Anti-patterns with nouns — restructure to "DO NOT <verb> <noun>":
       - BAD: "No business logic in controllers"
       - GOOD: "DO NOT put business logic in controllers"
       - BAD: "No HTML in translation strings"
       - GOOD: "DO NOT include HTML in translation strings"
    b) Anti-patterns with "Avoid" — convert to "DO NOT <verb>":
       - BAD: "Avoid deep nesting beyond two levels"
       - GOOD: "DO NOT nest beyond two levels of method calls"
    c) Passive/descriptive — convert to imperative:
       - BAD: "Method naming follows Ruby conventions"
       - GOOD: "Follow Ruby naming conventions for methods"
       - BAD: "Errors propagated appropriately"
       - GOOD: "Propagate errors appropriately (DO NOT silently swallow them)"
       - BAD: "Constants are frozen"
       - GOOD: "Freeze constants (`CONSTANT = 'value'.freeze`)"
    d) Descriptive defaults — convert to prohibition:
       - BAD: "Feature flags are enabled by default in tests"
       - GOOD: "DO NOT stub feature flags to `true` — they are enabled by
         default in the test environment"
    This ensures every rule reads as an instruction that agents follow,
    rather than background information they may ignore.
12. DO NOT duplicate rules across subsections. Compare rule **content**,
    not just headings: if a later rule says the same thing as an earlier
    one (even with different wording or under a different heading like
    "Common Mistakes" or "Guidelines"), drop the duplicate. When SSOT
    sources contain overlapping content (the same rule appearing in
    multiple source documents), emit it only once under the most relevant
    subsection. If the duplicate adds a meaningful nuance, merge it into
    the original rule rather than repeating.
13. When SSOT presents two related rules with a precedence relationship
    ("use X unless Y", "prefer X but use Z when W"), emit a single bullet
    using "Exception:", "Except when", or a semicolon, NOT two adjacent
    bullets that would read as contradictory. Example:
    - BAD (two adjacent bullets that contradict):
      - "Use `ApplicationRecord.transaction` instead of `ActiveRecord::Base.transaction`"
      - "Use `Model.transaction` (not `ApplicationRecord.transaction`) when all records belong to the same database"
    - GOOD (one bullet with adjacent precedence):
      - "Use `Model.transaction` when all records belong to the same database; use `ApplicationRecord.transaction` (not `ActiveRecord::Base.transaction`) only when the model is not known or records span multiple models"
14. Preserve cross-references between sub-domains. When a SSOT section
    explicitly links one rule to a related rule in another doc area
    (for example, "see also `multiple_databases.md` for cross-database
    cases"), append an inline parenthetical reference to the resulting
    checklist item rather than dropping the cross-link. Example:
    - BAD: "DO NOT use `dependent: :destroy` on associations"
    - GOOD: "DO NOT use `dependent: :destroy` on associations
      (cross-database cases have additional constraints — see
      database-fundamentals)"
15. Preserve exception framing. When a SSOT rule has a documented
    exception or escape hatch in the same source doc, keep the exception
    adjacent to the rule and prefix it with "Exception:" or "Except when".
    DO NOT split the rule and its exception across separate bullets.
    Example:
    - BAD (two separate bullets that read as contradictory):
      - "DO NOT use `pluck` to load IDs into memory for use as arguments
        in another query; use subqueries instead"
      - "When using CTEs with `update_all`, first pluck IDs from the CTE
        result and then scope the update to those IDs"
    - GOOD (single bullet with adjacent exception):
      - "DO NOT use `pluck` to load IDs into memory for use as arguments
        in another query; use subqueries instead. Exception: when using
        CTEs with `update_all`, first pluck IDs from the CTE result and
        scope the update to those IDs (the CTE is dropped otherwise)."

---
CURRENT AGENT FILE:
%{current_agent}

---
UPDATED SSOT DOCUMENTATION:
%{updated_docs}
%{baseline_section}

<!-- BASELINE_SECTION_TEMPLATE -->

16. Baseline rules (below) are exempt from rule 11 rephrasing — include
    them verbatim as provided.

---
BASELINE RULES (hand-curated, always include verbatim):
The following rules are hand-curated by the team and supplement the SSOT docs.
Include them in the output as-is, adding a dedicated subsection if needed.
Do not rephrase or omit these rules.

%{baseline_content}
