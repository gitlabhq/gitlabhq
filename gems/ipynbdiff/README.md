# IpynbDiff: Better diff for Jupyter Notebooks

This is a simple diff tool that cleans up Jupyter notebooks, transforming each [notebook](example/1/from.ipynb)
into a [readable markdown file](example/1/from_html.md), keeping the output of cells, and running the
diff after. Markdowns are generated using an opinionated Jupyter to Markdown conversion. This means
that the entire file is readable on the diff.

The result are diffs that are much easier to read:

| Diff                                | IpynbDiff                                             |
| ----------------------------------- | ----------------------------------------------------- |
| [Diff text](example/diff.txt)       | [IpynbDiff text](example/ipynbdiff_percent.txt)       |
| ![Diff image](example/img/diff.png) | ![IpynbDiff image](example/img/ipynbdiff_percent.png) |

This started as a port of [ipynbdiff](https://gitlab.com/gitlab-org/incubation-engineering/mlops/poc/ipynbdiff),
but now has extended functionality although not working as git driver.

## Usage

### Generating diffs

```ruby
IpynbDiff.diff(from_path, to_path, options)
```

Options:

```ruby
@default_transform_options = {
  preprocess_input: true, # Whether the input should be transformed
  write_output_to: nil, # Pass a path to save the output to a file
  format: :text, # These are the formats Diffy accepts https://github.com/samg/diffy
  sources_are_files: false, # Weather to use the from/to as string or path to a file
  raise_if_invalid_notebook: false, # Raises an error if the notebooks are invalid, otherwise returns nil
  transform_options: @default_transform_options, # See below for transform options
  diff_opts: {
    include_diff_info: false # These are passed to Diffy https://github.com/samg/diffy
  }
}
```

### Transforming the notebooks

It might be necessary to have the transformed files in addition to the diff.

```ruby
IpynbDiff.transform(notebook, options)
```

Options:

```ruby
@default_transform_options = {
    include_frontmatter: false, # Whether to include or not the notebook metadata (kernel, language, etc)
}
```
