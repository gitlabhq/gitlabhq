<!-- BEGIN TESTS -->
# GitLab Internal Extension Markdown

## Audio

See
[audio](https://docs.gitlab.com/ee/user/markdown.html#audio) in the GitLab Flavored Markdown documentation.

GLFM renders image elements as an audio player as long as the resource’s file extension is
one of the following supported audio extensions `.mp3`, `.oga`, `.ogg`, `.spx`, and `.wav`.
Audio ignore the alternative text part of an image declaration.

```````````````````````````````` example gitlab
![audio](audio.oga "audio title")
.
<p><audio src="audio.oga" title="audio title"></audio></p>
````````````````````````````````

Reference definitions work audio as well:

```````````````````````````````` example gitlab
[audio]: audio.oga "audio title"

![audio][audio]
.
<p><audio src="audio.oga" title="audio title"></audio></p>
````````````````````````````````

## Video

See
[videos](https://docs.gitlab.com/ee/user/markdown.html#videos) in the GitLab Flavored Markdown documentation.

GLFM renders image elements as a video player as long as the resource’s file extension is
one of the following supported video extensions  `.mp4`, `.m4v`, `.mov`, `.webm`, and `.ogv`.
Videos ignore the alternative text part of an image declaration.


```````````````````````````````` example gitlab
![video](video.m4v "video title")
.
<p><video src="video.m4v" title="video title"></video></p>
````````````````````````````````

Reference definitions work video as well:

```````````````````````````````` example gitlab
[video]: video.mov "video title"

![video][video]
.
<p><video src="video.mov" title="video title"></video></p>
````````````````````````````````

## Markdown Preview API Request Overrides

This section contains examples of all controllers which use `PreviewMarkdown` module
and use different `markdown_context_params`. They exercise the various `preview_markdown`
endpoints via `glfm_example_metadata.yml`.


`preview_markdown` exercising `groups` API endpoint and `UploadLinkFilter`:

```````````````````````````````` example gitlab
[groups-test-file](/uploads/groups-test-file)
.
<p><a href="groups-test-file">groups-test-file</a></p>
````````````````````````````````

`preview_markdown` exercising `projects` API endpoint and `RepositoryLinkFilter`:

```````````````````````````````` example gitlab
[projects-test-file](projects-test-file)
.
<p><a href="projects-test-file">projects-test-file</a></p>
````````````````````````````````

`preview_markdown` exercising `projects` API endpoint and `SnippetReferenceFilter`:

```````````````````````````````` example gitlab
This project snippet ID reference IS filtered: $88888
.
<p>This project snippet ID reference IS filtered: $88888</p>
````````````````````````````````

`preview_markdown` exercising personal (non-project) `snippets` API endpoint. This is
only used by the comment field on personal snippets. It has no unique custom markdown
extension behavior, and specifically does not render snippet references via
`SnippetReferenceFilter`, even if the ID is valid.

```````````````````````````````` example gitlab
This personal snippet ID reference is not filtered: $99999
.
<p>This personal snippet ID reference is not filtered: $99999</p>
````````````````````````````````

`preview_markdown` exercising project `wikis` API endpoint and `WikiLinkFilter`:

```````````````````````````````` example gitlab
[project-wikis-test-file](project-wikis-test-file)
.
<p><a href="project-wikis-test-file">project-wikis-test-file</a></p>
````````````````````````````````

`preview_markdown` exercising group `wikis` API endpoint and `WikiLinkFilter`. This example
also requires an EE license enabling the `group_wikis` feature:

```````````````````````````````` example gitlab
[group-wikis-test-file](group-wikis-test-file)
.
<p><a href="group-wikis-test-file">group-wikis-test-file</a></p>
````````````````````````````````
<!-- END TESTS -->
