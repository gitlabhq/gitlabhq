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
          "id": "section123",
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
    },
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
              "old_line": 62,
              "new_line": 62,
              "text": "        (new this).initialize(node, options);"
            },
            {
              "type": null,
              "old_line": 63,
              "new_line": 63,
              "text": "      }.bind(this));"
            },
            {
              "type": null,
              "old_line": 64,
              "new_line": 64,
              "text": "    }"
            },
            {
              "type": null,
              "old_line": 65,
              "new_line": 65,
              "text": ""
            }
          ]
        },
        {
          "conflict": true,
          "id": "section124",
          "lines": [
            {
              "type": "old",
              "old_line": 67,
              "new_line": null,
              "text": "    function removeFrom(selector) {"
            },
            {
              "type": "old",
              "old_line": 68,
              "new_line": null,
              "text": "      if (!selector) {"
            },
            {
              "type": "old",
              "old_line": 69,
              "new_line": null,
              "text": "        throw new Error(\"Component needs to be removeFrom'd a jQuery object, native node or selector string\");"
            },
            {
              "type": "old",
              "old_line": 70,
              "new_line": null,
              "text": "      }"
            },
            {
              "type": "old",
              "old_line": 71,
              "new_line": null,
              "text": " "
            },
            {
              "type": "old",
              "old_line": 72,
              "new_line": null,
              "text": "      $(selector).each(function(i, rawNode) {"
            },
            {
              "type": "old",
              "old_line": 73,
              "new_line": null,
              "text": "        var componentInfo = registry.findComponentInfo(this)"
            },
            {
              "type": "old",
              "old_line": 74,
              "new_line": null,
              "text": "        if (componentInfo && componentInfo.isAttachedTo(rawNode)) {"
            },
            {
              "type": "old",
              "old_line": 75,
              "new_line": null,
              "text": "          Object.keys(componentInfo.instances).forEach(function(index) {"
            },
            {
              "type": "old",
              "old_line": 76,
              "new_line": null,
              "text": "            var instance = componentInfo.instances[index].instance;"
            },
            {
              "type": "old",
              "old_line": 77,
              "new_line": null,
              "text": "            if (instance.node === rawNode) {"
            },
            {
              "type": "old",
              "old_line": 78,
              "new_line": null,
              "text": "              instance.teardown();"
            },
            {
              "type": "old",
              "old_line": 79,
              "new_line": null,
              "text": "            }"
            },
            {
              "type": "old",
              "old_line": 80,
              "new_line": null,
              "text": "          });"
            },
            {
              "type": "old",
              "old_line": 81,
              "new_line": null,
              "text": "        }"
            },
            {
              "type": "old",
              "old_line": 82,
              "new_line": null,
              "text": "      }.bind(this));"
            },
            {
              "type": "old",
              "old_line": 83,
              "new_line": null,
              "text": "    }"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 67,
              "text": "    function prettyPrintMixins() {"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 68,
              "text": "      //could be called from constructor or constructor.prototype"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 69,
              "text": "      var mixedIn = this.mixedIn || this.prototype.mixedIn || [];"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 70,
              "text": "      return mixedIn.map(function(mixin) {"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 71,
              "text": "        if (mixin.name == null) {"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 72,
              "text": "          // function name property not supported by this browser, use regex"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 73,
              "text": "          var m = mixin.toString().match(functionNameRegEx);"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 74,
              "text": "          return (m && m[1]) ? m[1] : '';"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 75,
              "text": "        } else {"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 76,
              "text": "          return (mixin.name != 'withBase') ? mixin.name : '';"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 77,
              "text": "        }"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 78,
              "text": "      }).filter(Boolean).join(', ');"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 79,
              "text": "    };"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 80,
              "text": ""
            }
          ]
        },
        {
          "conflict": false,
          "lines": [
            {
              "type": null,
              "old_line": 84,
              "new_line": 81,
              "text": ""
            },
            {
              "type": null,
              "old_line": 85,
              "new_line": 82,
              "text": "    // define the constructor for a custom component type"
            },
            {
              "type": null,
              "old_line": 86,
              "new_line": 83,
              "text": "    // takes an unlimited number of mixin functions as arguments"
            },
            {
              "type": null,
              "old_line": 87,
              "new_line": 84,
              "text": "    // typical api call with 3 mixins: define(timeline, withTweetCapability, withScrollCapability);"
            }
          ]
        }
      ]
    },
    {
      "commit_sha": "c68b43c7c22b5b96e0e7b3b5fa56eb3f2cea5e21",
      "old_path": "lib/registry.js",
      "new_path": "lib/registry.js",
      "sections": [
        {
          "conflict": false,
          "lines": [
            {
              "type": null,
              "old_line": 159,
              "new_line": 159,
              "text": ""
            },
            {
              "type": null,
              "old_line": 160,
              "new_line": 160,
              "text": "var thisInstanceInfo = this.allInstances[k]"
            }
          ]
        },
        {
          "conflict": true,
          "id": "section125",
          "lines": [
            {
              "type": "old",
              "old_line": 161,
              "new_line": null,
              "text": "if(thisInstanceInfo.instance.node == node){"
            },
            {
              "type": "new",
              "old_line": null,
              "new_line": 161,
              "text": "if (thisInstanceInfo.instance.node === node) {"
            }
          ]
        },
        {
          "conflict": false,
          "lines": [
            {
              "type": null,
              "old_line": 162,
              "new_line": 162,
              "text": "result.push(thisInstanceInfo);"
            }
          ]
        }
      ]
    }
  ]
}
