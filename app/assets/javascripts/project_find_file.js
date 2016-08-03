(function() {
  var bind = function(fn, me){ return function(){ return fn.apply(me, arguments); }; };

  this.ProjectFindFile = (function() {
    var highlighter;

    function ProjectFindFile(element1, options) {
      this.element = element1;
      this.options = options;
      this.goToBlob = bind(this.goToBlob, this);
      this.goToTree = bind(this.goToTree, this);
      this.selectRowDown = bind(this.selectRowDown, this);
      this.selectRowUp = bind(this.selectRowUp, this);
      this.filePaths = {};
      this.inputElement = this.element.find(".file-finder-input");
      this.initEvent();
      this.inputElement.focus();
      this.load(this.options.url);
    }

    ProjectFindFile.prototype.initEvent = function() {
      this.inputElement.off("keyup");
      this.inputElement.on("keyup", (function(_this) {
        return function(event) {
          var oldValue, ref, target, value;
          target = $(event.target);
          value = target.val();
          oldValue = (ref = target.data("oldValue")) != null ? ref : "";
          if (value !== oldValue) {
            target.data("oldValue", value);
            _this.findFile();
            return _this.element.find("tr.tree-item").eq(0).addClass("selected").focus();
          }
        };
      })(this));
      return this.element.find(".tree-content-holder .tree-table").on("click", function(event) {
        var path;
        if (event.target.nodeName !== "A") {
          path = this.element.find(".tree-item-file-name a", this).attr("href");
          if (path) {
            return location.href = path;
          }
        }
      });
    };

    ProjectFindFile.prototype.findFile = function() {
      var result, searchText;
      searchText = this.inputElement.val();
      result = searchText.length > 0 ? fuzzaldrinPlus.filter(this.filePaths, searchText) : this.filePaths;
      return this.renderList(result, searchText);
    };

    ProjectFindFile.prototype.load = function(url) {
      return $.ajax({
        url: url,
        method: "get",
        dataType: "json",
        success: (function(_this) {
          return function(data) {
            _this.element.find(".loading").hide();
            _this.filePaths = data;
            _this.findFile();
            return _this.element.find(".files-slider tr.tree-item").eq(0).addClass("selected").focus();
          };
        })(this)
      });
    };

    ProjectFindFile.prototype.renderList = function(filePaths, searchText) {
      var blobItemUrl, filePath, html, i, j, len, matches, results;
      this.element.find(".tree-table > tbody").empty();
      results = [];
      for (i = j = 0, len = filePaths.length; j < len; i = ++j) {
        filePath = filePaths[i];
        if (i === 20) {
          break;
        }
        if (searchText) {
          matches = fuzzaldrinPlus.match(filePath, searchText);
        }
        blobItemUrl = this.options.blobUrlTemplate + "/" + filePath;
        html = this.makeHtml(filePath, matches, blobItemUrl);
        results.push(this.element.find(".tree-table > tbody").append(html));
      }
      return results;
    };

    highlighter = function(element, text, matches) {
      var highlightText, j, lastIndex, len, matchIndex, matchedChars, unmatched;
      lastIndex = 0;
      highlightText = "";
      matchedChars = [];
      for (j = 0, len = matches.length; j < len; j++) {
        matchIndex = matches[j];
        unmatched = text.substring(lastIndex, matchIndex);
        if (unmatched) {
          if (matchedChars.length) {
            element.append(matchedChars.join("").bold());
          }
          matchedChars = [];
          element.append(document.createTextNode(unmatched));
        }
        matchedChars.push(text[matchIndex]);
        lastIndex = matchIndex + 1;
      }
      if (matchedChars.length) {
        element.append(matchedChars.join("").bold());
      }
      return element.append(document.createTextNode(text.substring(lastIndex)));
    };

    ProjectFindFile.prototype.makeHtml = function(filePath, matches, blobItemUrl) {
      var $tr;
      $tr = $("<tr class='tree-item'><td class='tree-item-file-name'><i class='fa fa-file-text-o fa-fw'></i><span class='str-truncated'><a></a></span></td></tr>");
      if (matches) {
        $tr.find("a").replaceWith(highlighter($tr.find("a"), filePath, matches).attr("href", blobItemUrl));
      } else {
        $tr.find("a").attr("href", blobItemUrl).text(filePath);
      }
      return $tr;
    };

    ProjectFindFile.prototype.selectRow = function(type) {
      var next, rows, selectedRow;
      rows = this.element.find(".files-slider tr.tree-item");
      selectedRow = this.element.find(".files-slider tr.tree-item.selected");
      if (rows && rows.length > 0) {
        if (selectedRow && selectedRow.length > 0) {
          if (type === "UP") {
            next = selectedRow.prev();
          } else if (type === "DOWN") {
            next = selectedRow.next();
          }
          if (next.length > 0) {
            selectedRow.removeClass("selected");
            selectedRow = next;
          }
        } else {
          selectedRow = rows.eq(0);
        }
        return selectedRow.addClass("selected").focus();
      }
    };

    ProjectFindFile.prototype.selectRowUp = function() {
      return this.selectRow("UP");
    };

    ProjectFindFile.prototype.selectRowDown = function() {
      return this.selectRow("DOWN");
    };

    ProjectFindFile.prototype.goToTree = function() {
      return location.href = this.options.treeUrl;
    };

    ProjectFindFile.prototype.goToBlob = function() {
      var path;
      path = this.element.find(".tree-item.selected .tree-item-file-name a").attr("href");
      if (path) {
        return location.href = path;
      }
    };

    return ProjectFindFile;

  })();

}).call(this);
