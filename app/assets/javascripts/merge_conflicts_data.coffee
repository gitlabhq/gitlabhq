window.mergeConflictsData = {
  "target_branch": "master",
  "source_branch": "mc-ui",
  "files": [
    {
      "commit_sha": "b5fa56eb3f2cea5e21c68b43c7c22b5b96e0e7b3",
      "old_path": "lib/component.js",
      "new_path": "lib/component.js",
      "sections": [
        {
          "conflict": false,
          "lines": [
            {
              "type": null,
              "old_line": 206,
              "new_line": 206,
              "text": ""
            },
            {
              "type": null,
              "old_line": 207,
              "new_line": 207,
              "text": "var options = utils.merge.apply(utils, args);"
            }
          ]
        },
        {
          "conflict": true,
          "id": "section-id-123",
          "lines": [
            {
              "type": "old",
              "old_line": 208,
              "new_line": null,
              "text": "$(selector).each(function(i, rawNode) {"
            },
            {
              "type": "old",
              "old_line": 209,
              "new_line": null,
              "text": "var componentInfo = registry.findComponentInfo(this)"
            },
            {
              "type": "old",
              "old_line": 210,
              "new_line": null,
              "text": "if (componentInfo && componentInfo.isAttachedTo(rawNode)) {"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 208,
              "text": "$(selector).each(function(i, node) {"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 209,
              "text": "if (componentInfo && componentInfo.isAttachedTo(node)) {"
            }
          ]
        },
        {
          "conflict": false,
          "lines": [
            {
              "type": null,
              "old_line": 211,
              "new_line": 210,
              "text": "return;"
            },
            {
              "type": null,
              "old_line": 212,
              "new_line": 211,
              "text": "}"
            },
            {
              "type": null,
              "old_line": null,
              "new_line": 212,
              "text": ""
            },
            {
              "type": null,
              "old_line": 213,
              "new_line": 213,
              "text": ""
            }
          ]
        }
      ]
    }
  ]
}
