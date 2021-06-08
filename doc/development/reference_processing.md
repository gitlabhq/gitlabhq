---
stage: none
group: unassigned
info: To determine the technical writer assigned to the Stage/Group associated with this page, see https://about.gitlab.com/handbook/engineering/ux/technical-writing/#assignments
description: 'An introduction to reference parsers and reference filters, and a guide to their implementation.'
---

# Reference processing

[GitLab Flavored Markdown](../user/markdown.md) includes the ability to process
references to a range of GitLab domain objects. This is implemented by two
abstractions in the `Banzai` pipeline: `ReferenceFilter` and `ReferenceParser`.
This page explains what these are, how they are used, and how you would
implement a new filter/parser pair.

Each `ReferenceFilter` must have a corresponding `ReferenceParser`.

It is possible to share reference parsers between filters - if two filters find
and link the same type of objects (as specified by the `data-reference-type`
attribute), then we only need one reference parser for that type of domain
object.

## Banzai pipeline

`Banzai` pipeline returns the `result` Hash after being filtered by the Pipeline.

The `result` Hash is passed to each filter for modification. This is where Filters store extracted information from the content.
It contains:

- An `:output` key with the DocumentFragment or String HTML markup based on the output of the last filter in the pipeline.
- A `:reference_filter_nodes` key with the list of DocumentFragment `nodes` that are ready for processing, updated by each filter in the pipeline.

## Reference filters

The first way that references are handled is by reference filters. These are
the tools that identify short-code and URI references from markup documents and
transform them into structured links to the resources they represent.

For example, the class
[`Banzai::Filter::IssueReferenceFilter`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/banzai/filter/issue_reference_filter.rb)
is responsible for handling references to issues, such as
`gitlab-org/gitlab#123` and `https://gitlab.com/gitlab-org/gitlab/-/issues/200048`.

All reference filters are instances of [`HTML::Pipeline::Filter`](https://www.rubydoc.info/github/jch/html-pipeline/HTML/Pipeline/Filter),
and inherit (often indirectly) from [`Banzai::Filter::ReferenceFilter`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/banzai/filter/reference_filter.rb).

`HTML::Pipeline::Filter` has a simple interface consisting of `#call`, a void
method that mutates the current document. `ReferenceFilter` provides methods
that make defining suitable `#call` methods easier. Most reference filters
however do not inherit from either of these classes directly, but from
[`AbstractReferenceFilter`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/banzai/filter/abstract_reference_filter.rb),
which provides a higher-level interface.

Subclasses of `AbstractReferenceFilter` generally do not override `#call`; instead,
a minimum implementation of `AbstractReferenceFilter` should define:

- `.reference_type`: The type of domain object.

  This is usually a keyword, and is used to set the `data-reference-type` attribute
  on the generated link, and is an important part of the interaction with the
  corresponding `ReferenceParser` (see below).

- `.object_class`: a reference to the class of the objects a filter refers to.

  This is used to:

  - Find the regular expressions used to find references. The class should
    include [`Referable`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/concerns/referable.rb)
    and thus define two regular expressions: `.link_reference_pattern` and
    `.reference_pattern`, both of which should contain a named capture group
    named the value of `ReferenceFilter.object_sym`.
  - Compute the `.object_name`.
  - Compute the `.object_sym` (the group name in the reference patterns).

- `.parse_symbol(string)`: parse the text value to an object identifier (`#to_i` by default).
- `#record_identifier(record)`: the inverse of `.parse_symbol`, that is, transform a domain object to an identifier (`#id` by default).
- `#url_for_object(object, parent_object)`: generate the URL for a domain object.
- `#find_object(parent_object, id)`: given the parent (usually a [`Project`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/app/models/project.rb))
 and an identifier, find the object. For example, this in a reference filter for
 merge requests, this might be `project.merge_requests.where(iid: iid)`.

### Add a new reference prefix and filter

For reference filters for new objects, use a prefix format following the pattern
`^<object_type>#`, because:

1. Varied single-character prefixes are hard for users to track. Especially for
   lower-use object types, this can diminish value for the feature.
1. Suitable single-character prefixes are limited.
1. Following a consistent pattern allows users to infer the existence of new features.

To add a reference prefix for a new object `apple`,which has both a name and ID,
format the reference as:

- `^apple#123` for identification by ID.
- `^apple#"Granny Smith"` for identification by name.

### Performance

#### Find object optimization

This default implementation is not very efficient, because we need to call
`#find_object` for each reference, which may require issuing a DB query every
time. For this reason, most reference filter implementations instead use an
optimization included in `AbstractReferenceFilter`:

> `AbstractReferenceFilter` provides a lazily initialized value
> `#records_per_parent`, which is a mapping from parent object to a collection
> of domain objects.

To use this mechanism, the reference filter must implement the
method: `#parent_records(parent, set_of_identifiers)`, which must return an
enumerable of domain objects.

This allows such classes to define `#find_object` (as
[`IssuableReferenceFilter`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/banzai/filter/issuable_reference_filter.rb)
does) as:

```ruby
def find_object(parent, iid)
  records_per_parent[parent][iid]
end
```

This makes the number of queries linear in the number of projects. We only need
to implement `parent_records` method when we call `records_per_parent` in our
reference filter.

#### Filtering nodes optimization

Each `ReferenceFilter` would iterate over all `<a>` and `text()` nodes in a document.

Not all nodes are processed, document is filtered only for nodes that we want to process.
We are skipping:

- Link tags already processed by some previous filter (if they have a `gfm` class).
- Nodes with the ancestor node that we want to ignore (`ignore_ancestor_query`).
- Empty line.
- Link tags with the empty `href` attribute.

To avoid filtering such nodes for each `ReferenceFilter`, we do it only once and store the result in the result Hash of the pipeline as `result[:reference_filter_nodes]`.

Pipeline `result` is passed to each filter for modification, so every time when `ReferenceFilter` replaces text or link tag, filtered list (`reference_filter_nodes`) are updated for the next filter to use.

## Reference parsers

In a number of cases, as a performance optimization, we render Markdown to HTML
once, cache the result and then present it to users from the cached value. For
example this happens for notes, issue descriptions, and merge request
descriptions. A consequence of this is that a rendered document might refer to
a resource that some subsequent readers should not be able to see.

For example, you might create an issue, and refer to a confidential issue `#1234`,
which you have access to. This is rendered in the cached HTML as a link to
that confidential issue, with data attributes containing its ID, the ID of the
project and other confidential data. A later reader, who has access to your issue
might not have permission to read issue `#1234`, and so we need to redact
these sensitive pieces of data. This is what `ReferenceParser` classes do.

A reference parser is linked to the object that it handles by the link
advertising this relationship in the `data-reference-type` attribute (set by the
reference filter). This is used by the
[`ReferenceRedactor`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/banzai/reference_redactor.rb)
to compute which nodes should be visible to users:

```ruby
def nodes_visible_to_user(nodes)
  per_type = Hash.new { |h, k| h[k] = [] }
  visible = Set.new

  nodes.each do |node|
    per_type[node.attr('data-reference-type')] << node
  end

  per_type.each do |type, nodes|
    parser = Banzai::ReferenceParser[type].new(context)

    visible.merge(parser.nodes_visible_to_user(user, nodes))
  end

  visible
end
```

The key part here is `Banzai::ReferenceParser[type]`, which is used to look up
the correct reference parser for each type of domain object. This requires that
each reference parser must:

- Be placed in the `Banzai::ReferenceParser` namespace.
- Implement the `.nodes_visible_to_user(user, nodes)` method.

In practice, all reference parsers inherit from [`BaseParser`](https://gitlab.com/gitlab-org/gitlab/-/blob/master/lib/banzai/reference_parser/base_parser.rb), and are implemented by defining:

- `.reference_type`, which should equal `ReferenceFilter.reference_type`.
- And by implementing one or more of:
  - `#nodes_visible_to_user(user, nodes)` for finest grain control.
  - `#can_read_reference?` needed if `nodes_visible_to_user` is not overridden.
  - `#references_relation` an active record relation for objects by ID.
  - `#nodes_user_can_reference(user, nodes)` to filter nodes directly.

A failure to implement this class for each reference type means that the
application raises exceptions during Markdown processing.
