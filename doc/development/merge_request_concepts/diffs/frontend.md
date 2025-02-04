---
stage: Create
group: Code Review
info: Any user with at least the Maintainer role can merge updates to this content. For details, see https://docs.gitlab.com/ee/development/development_processes.html#development-guidelines-review.
description: "Developer documentation explaining how the different parts of the Vue-based frontend diffs are generated."
title: Merge request diffs frontend overview
---

This document provides an overview on how the frontend diffs Vue application works, and
the various different parts that exist. It should help contributors:

- Understand how the diffs Vue app is set up.
- Identify any areas that need improvement.

This document is a living document. Update it whenever anything significant changes in
the diffs application.

## Diffs Vue app

### Components

The Vue app for rendering diffs uses many different Vue components, some of which get shared
with other areas of the GitLab app. The below chart shows the direction for which components
get rendered.

This chart contains several types of items:

| Legend item | Interpretation |
| ----------- | -------------- |
| `xxx~~`, `ee-xxx~~` | A shortened directory path name. Can be found in `[ee]/app/assets/javascripts`, and omits `0..n` nested folders. |
| Rectangular nodes | Files. |
| Oval nodes | Plain language describing a deeper concept. |
| Double-rectangular nodes | Simplified code branch. |
| Diamond and circle nodes | Branches that have 2 (diamond) or 3+ (circle) options. |
| Pendant / banner nodes (left notch, right square) | A parent directory to shorten nested paths. |
| `./` | A path relative to the closest parent directory pendant node. Non-relative paths nested under parent pendant nodes are not in that directory. |

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
  flowchart TB
    accTitle: Component rendering
    accDescr: Flowchart of how components are rendered in the GitLab front end
    classDef code font-family: monospace;

    A["diffs~~app.vue"]
    descVirtualScroller(["Virtual Scroller"])
    codeForFiles[["v-for(diffFiles)"]]
    B["diffs~~diff_file.vue"]
    C["diffs~~diff_file_header.vue"]
    D["diffs~~diff_stats.vue"]
    E["diffs~~diff_content.vue"]
    boolFileIsText{isTextFile}
    boolOnlyWhitespace{isWhitespaceOnly}
    boolNotDiffable{notDiffable}
    boolNoPreview{noPreview}
    descShowChanges(["Show button to &quot;Show changes&quot;"])
    %% Non-text changes
    dirDiffViewer>"vue_shared~~diff_viewer"]
    F["./viewers/not_diffable.vue"]
    G["./viewers/no_preview.vue"]
    H["./diff_viewer.vue"]
    I["diffs~~diff_view.vue"]
    boolIsRenamed{isRenamed}
    boolIsModeChanged{isModeChanged}
    boolFileHasNoPath{hasNewPath}
    boolIsImage{isImage}
    J["./viewers/renamed.vue"]
    K["./viewers/mode_changed.vue"]
    descNoViewer(["No viewer is rendered"])
    L["./viewers/image_diff_viewer.vue"]
    M["./viewers/download.vue"]
    N["vue_shared~~download_diff_viewer.vue"]
    boolImageIsReplaced{isReplaced}
    O["vue_shared~~image_viewer.vue"]
    switchImageMode((image_diff_viewer.mode))
    P["./viewers/image_diff/onion_skin_viewer.vue"]
    Q["./viewers/image_diff/swipe_viewer.vue"]
    R["./viewers/image_diff/two_up_viewer.vue"]
    S["diffs~~image_diff_overlay.vue"]
    codeForImageDiscussions[["v-for(discussions)"]]
    T["vue_shared~~design_note_pin.vue"]
    U["vue_shared~~user_avatar_link.vue"]
    V["diffs~~diff_discussions.vue"]
    W["batch_comments~~diff_file_drafts.vue"]
    codeForTwoUpDiscussions[["v-for(discussions)"]]
    codeForTwoUpDrafts[["v-for(drafts)"]]
    X["notes~~notable_discussion.vue"]
    %% Text-file changes
    codeForDiffLines[["v-for(diffLines)"]]
    Y["diffs~~diff_expansion_cell.vue"]
    Z["diffs~~diff_row.vue"]
    AA["diffs~~diff_line.vue"]
    AB["batch_comments~~draft_note.vue"]
    AC["diffs~~diff_comment_cell.vue"]
    AD["diffs~~diff_gutter_avatars.vue"]
    AE["ee-diffs~~inline_findings_gutter_icon_dropdown.vue"]
    AF["notes~~noteable_note.vue"]
    AG["notes~~note_actions.vue"]
    AH["notes~~note_body.vue"]
    AI["notes~~note_header.vue"]
    AJ["notes~~reply_button.vue"]
    AK["notes~~note_awards_list.vue"]
    AL["notes~~note_edited_text.vue"]
    AM["notes~~note_form.vue"]
    AN["vue_shared~~awards_list.vue"]
    AO["emoji~~picker.vue"]
    AP["emoji~~emoji_list.vue"]
    descEmojiVirtualScroll(["Virtual Scroller"])
    AQ["emoji~~category.vue"]
    AR["emoji~emoji_category.vue"]
    AS["vue_shared~~markdown_editor.vue"]

    class codeForFiles,codeForImageDiscussions code;
    class codeForTwoUpDiscussions,codeForTwoUpDrafts code;
    class codeForDiffLines code;
    %% Also apply code styling to this switch node
    class switchImageMode code;
    %% Also apply code styling to these boolean nodes
    class boolFileIsText,boolOnlyWhitespace,boolNotDiffable,boolNoPreview code;
    class boolIsRenamed,boolIsModeChanged,boolFileHasNoPath,boolIsImage code;
    class boolImageIsReplaced code;

    A --> descVirtualScroller
    A -->|"Virtual Scroller is
    disabled when
    Find in page search
    (Cmd/Ctrl+f) is used."|codeForFiles
    descVirtualScroller --> codeForFiles
    codeForFiles --> B --> C --> D
    B --> E

    %% File view flags cascade
    E --> boolFileIsText
    boolFileIsText --> |yes| I
    boolFileIsText --> |no| boolOnlyWhitespace

    boolOnlyWhitespace --> |yes| descShowChanges
    boolOnlyWhitespace --> |no| dirDiffViewer

    dirDiffViewer --> H

    H --> boolNotDiffable

    boolNotDiffable --> |yes| F
    boolNotDiffable --> |no| boolNoPreview

    boolNoPreview --> |yes| G
    boolNoPreview --> |no| boolIsRenamed

    boolIsRenamed --> |yes| J
    boolIsRenamed --> |no| boolIsModeChanged

    boolIsModeChanged --> |yes| K
    boolIsModeChanged --> |no| boolFileHasNoPath

    boolFileHasNoPath --> |yes| boolIsImage
    boolFileHasNoPath --> |no| descNoViewer

    boolIsImage --> |yes| L
    boolIsImage --> |no| M
    M --> N

    %% Image diff viewer
    L --> boolImageIsReplaced

    boolImageIsReplaced --> |yes| switchImageMode
    boolImageIsReplaced --> |no| O

    switchImageMode -->|"'twoup' (default)"| R
    switchImageMode -->|'onion'| P
    switchImageMode -->|'swipe'| Q

    P & Q --> S
    S --> codeForImageDiscussions
    S --> AM

    R-->|"Rendered in
    note container div"|U & W & V
    %% Do not combine this with the "P & Q --> S" statement above
    %%     The order of these node relationships defines the
    %%     layout of the graph, and we need it in this order.
    R --> S

    V --> codeForTwoUpDiscussions
    W --> codeForTwoUpDrafts

    %% This invisible link forces `noteable_discussion`
    %%     to render above `design_note_pin`
    X ~~~ T

    codeForTwoUpDrafts --> AB
    codeForImageDiscussions & codeForTwoUpDiscussions & codeForTwoUpDrafts --> T
    codeForTwoUpDiscussions --> X

    %% Text file diff viewer
    I --> codeForDiffLines
    codeForDiffLines --> Z
    codeForDiffLines -->|"isMatchLine?"| Y
    codeForDiffLines -->|"hasCodeQuality?"| AA
    codeForDiffLines -->|"hasDraftNote(s)?"| AB

    Z -->|"hasCodeQuality?"| AE
    Z -->|"hasDiscussions?"| AD

    AA --> AC

    %% Draft notes
    AB --> AF
    AF --> AG & AH & AI
    AG --> AJ
    AH --> AK & AL & AM
    AK --> AN --> AO --> AP --> descEmojiVirtualScroll --> AQ --> AR
    AM --> AS
```

Some of the components are rendered more than others, but the main component is `diff_row.vue`.
This component renders every diff line in a diff file. For performance reasons, this
component is a functional component. However, when we upgrade to Vue 3, this is no longer
required.

The main diff app component is the main entry point to the diffs app. One of the most important parts
of this component is to dispatch the action that assigns discussions to diff lines. This action
gets dispatched after the metadata request is completed, and after the batch diffs requests are
finished. There is also a watcher set up to watches for changes in both the diff files array and the notes
array. Whenever a change happens here, the set discussion action gets dispatched.

The DiffRow component is set up in a way that allows for us to store the diff line data in one format.
Previously, we had to request two different formats for inline and side-by-side. The DiffRow component
then uses this standard format to render the diff line data. With this standard format, the user
can then switch between inline and side-by-side without the need to re-fetch any data.

NOTE:
For this component, a lot of the data used and rendered gets memoized and cached, based on
various conditions. It is possible that data sometimes gets cached between each different
component render.

### Vuex store

The Vuex store for the diffs app consists of 3 different modules:

- Notes
- Diffs
- Batch comments

The notes module is responsible for the discussions, including diff discussions. In this module,
the discussions get fetched, and the polling for new discussions is setup. This module gets shared
with the issue app as well, so changes here need to be tested in both issues and merge requests.

The diffs module is responsible for the everything related to diffs. This includes, but is not limited
to, fetching diffs, assigning diff discussions to lines, and creating diff discussions.

Finally, the batch comments module is not complex, and is responsible only for the draft comments feature.
However, this module does dispatch actions in the notes and diff modules whenever draft comments
are published.

### API Requests

#### Metadata

The diffs metadata endpoint exists to fetch the base data the diffs app requires quickly, without
the need to fetch all the diff files. This includes, but is not limited to:

- Diff filenames, including some extra meta data for diff files
- Added and removed line numbers
- Branch names
- Diff versions

The most important part of the metadata response is the diff filenames. This data allows the diffs
app to render the file browser inside of the diffs app, without waiting for all batch diffs
requests to complete.

When the metadata response is received, the diff file data is processed into the correct structure
that the frontend requires to render the file browser in either tree view or list view.

The structure for this file object is:

```javascript
{
  "key": "",
  "path": "",
  "name": "",
  "type": "",
  "tree": [],
  "changed": true,
  "diffLoaded": false,
  "filePaths": {
    "old": file.old_path,
    "new": file.new_path
  },
  "tempFile": false,
  "deleted": false,
  "fileHash": "",
  "addedLines": 1,
  "removedLines": 1,
  "parentPath": "/",
  "submodule": false
}
```

#### Batch diffs

To reduce the response size for the diffs endpoint, we are splitting this response up into different
requests, to:

- Reduces the response size of each request.
- Allows the diffs app to start rendering diffs as quickly as the first request finishes.

To make the first request quicker, the request gets sent asking for a small amount of
diffs. The number of diffs requested then increases, until the maximum number of diffs per request is 30.

When the request finishes, the diffs app formats the data received into a format that makes
it easier for the diffs app to render the diffs lines.

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TD
    accTitle: Formatting diffs
    accDescr: A flowchart of steps taken when rendering a diff, including retrieval and display preparations
    A[fetchDiffFilesBatch] -->
    B[commit SET_DIFF_DATA_BATCH] -->
    C[prepareDiffData] -->
    D[prepareRawDiffFile] -->
    E[ensureBasicDiffFileLines] -->
    F[prepareDiffFileLines] -->
    G[finalizeDiffFile] -->
    H[deduplicateFilesList]
```

After this has been completed, the diffs app can now begin to render the diff lines. However, before
anything can be rendered the diffs app does one more format. It takes the diff line data, and maps
the data into a format for easier switching between inline and side-by-side modes. This
formatting happens in a computed property inside the `diff_content.vue` component.

### Render queue

NOTE:
This _might_ not be required any more. Some investigation work is required to decide
the future of the render queue. The virtual scroll bar we created has probably removed
any performance benefit we got from this approach.

To render diffs quickly, we have a render queue that allows the diffs to render only if the
browser is idle. This saves the browser getting frozen when rendering a lot of large diffs at once,
and allows us to reduce the total blocking time.

This pipeline of rendering files happens only if all the below conditions are `true` for every
diff file. If any of these are `false`, then this render queue does not happen and the diffs get
rendered as expected.

- Are the diffs in this file already rendered?
- Does this diff have a viewer? (Meaning, is it not a download?)
- Is the diff expanded?

This chart gives a brief overview of the pipeline that happens:

```mermaid
%%{init: { "fontFamily": "GitLab Sans" }}%%
graph TD
    accTitle: Render queue pipeline
    accDescr: Flowchart of the steps in the render queue pipeline
    A[startRenderDiffsQueue] -->B
    B[commit RENDER_FILE current file index] -->C
    C[canRenderNextFile?]
    C -->|Yes| D[Render file] -->B
    C -->|No| E[Re-run requestIdleCallback] -->C
```

The checks that happen:

- Is the idle time remaining less than 5 ms?
- Have we already tried to render this file 4 times?

After these checks happen, the file is marked in Vuex as `renderable`, which allows the diffs
app to start rendering the diff lines and discussions.
