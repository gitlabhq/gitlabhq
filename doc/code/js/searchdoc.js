Searchdoc = {};

// navigation.js ------------------------------------------

Searchdoc.Navigation = new function() {
    this.initNavigation = function() {
        var _this = this;
        
        $(document).keydown(function(e) {
            _this.onkeydown(e);
        }).keyup(function(e) {
            _this.onkeyup(e);
        });
        
        this.navigationActive = true;
    }
    
    this.setNavigationActive = function(state) {
        this.navigationActive = state;
        this.clearMoveTimeout();
    }


    this.onkeyup = function(e) {
        if (!this.navigationActive) return;
        switch(e.keyCode) {
            case 37: //Event.KEY_LEFT:
            case 38: //Event.KEY_UP:
            case 39: //Event.KEY_RIGHT:
            case 40: //Event.KEY_DOWN:
            case 73: // i - qwerty
            case 74: // j
            case 75: // k
            case 76: // l
            case 67: // c - dvorak
            case 72: // h 
            case 84: // t
            case 78: // n
                this.clearMoveTimeout();
                break;
            }
    }

    this.onkeydown = function(e) {
        if (!this.navigationActive) return;
        switch(e.keyCode) {
            case 37: //Event.KEY_LEFT:
            case 74: // j (qwerty)
            case 72: // h (dvorak)
                if (this.moveLeft()) e.preventDefault();
                break;
            case 38: //Event.KEY_UP:
            case 73: // i (qwerty)
            case 67: // c (dvorak)
                if (e.keyCode == 38 || e.ctrlKey) {
                    if (this.moveUp()) e.preventDefault();
                    this.startMoveTimeout(false);
                }
                break;
            case 39: //Event.KEY_RIGHT:
            case 76: // l (qwerty)
            case 78: // n (dvorak)
                if (this.moveRight()) e.preventDefault();
                break;
            case 40: //Event.KEY_DOWN:
            case 75: // k (qwerty)
            case 84: // t (dvorak)
                if (e.keyCode == 40 || e.ctrlKey) {
                    if (this.moveDown()) e.preventDefault();
                    this.startMoveTimeout(true);
                }
                break;
            case 9: //Event.KEY_TAB:
            case 13: //Event.KEY_RETURN:
                if (this.$current) this.select(this.$current);
                break;
            case 83: // s (qwerty)
            case 79: // o (dvorak)
                if (e.ctrlKey) {
                    $('#search').focus();
                    e.preventDefault();
                }
                break;
        }
        if (e.ctrlKey && e.shiftKey) this.select(this.$current);
    }

    this.clearMoveTimeout = function() {
        clearTimeout(this.moveTimeout); 
        this.moveTimeout = null;
    }

    this.startMoveTimeout = function(isDown) {
        if (!$.browser.mozilla && !$.browser.opera) return;
        if (this.moveTimeout) this.clearMoveTimeout();
        var _this = this;
    
        var go = function() {
            if (!_this.moveTimeout) return;
            _this[isDown ? 'moveDown' : 'moveUp']();
            _this.moveTimout = setTimeout(go, 100);
        }
        this.moveTimeout = setTimeout(go, 200);
    }    
    
    this.moveRight = function() {
    }
    
    this.moveLeft = function() {
    }

    this.move = function(isDown) {
    }

    this.moveUp = function() {
        return this.move(false);
    }

    this.moveDown = function() {
        return this.move(true);
    }    
}


// scrollIntoView.js --------------------------------------

function scrollIntoView(element, view) {
    var offset, viewHeight, viewScroll, height;
    offset = element.offsetTop;
    height = element.offsetHeight;
    viewHeight = view.offsetHeight;
    viewScroll = view.scrollTop;
    if (offset - viewScroll + height > viewHeight) {
        view.scrollTop = offset - viewHeight + height;
    }
    if (offset < viewScroll) {
        view.scrollTop = offset;
    }
}

// panel.js -----------------------------------------------

Searchdoc.Panel = function(element, data, tree, frame) {
    this.$element = $(element);
    this.$input = $('input', element).eq(0);
    this.$result = $('.result ul', element).eq(0);
    this.frame = frame;
    this.$current = null;
    this.$view = this.$result.parent();
    this.data = data;
    this.searcher = new Searcher(data.index);

    this.tree = new Searchdoc.Tree($('.tree', element), tree, this);
    this.init();
}

Searchdoc.Panel.prototype = $.extend({}, Searchdoc.Navigation, new function() {
    var suid = 1;

    this.init = function() {
        var _this = this;
        var observer = function() {
            _this.search(_this.$input[0].value);
        };
        this.$input.keyup(observer);
        this.$input.click(observer); // mac's clear field
    
        this.searcher.ready(function(results, isLast) {
            _this.addResults(results, isLast);
        })
    
        this.$result.click(function(e) {
            _this.$current.removeClass('current');
            _this.$current = $(e.target).closest('li').addClass('current');
            _this.select();
            _this.$input.focus();
        });
        
        this.initNavigation();
        this.setNavigationActive(false);
    }

    this.search = function(value, selectFirstMatch) {
        value = jQuery.trim(value).toLowerCase();
        this.selectFirstMatch = selectFirstMatch;
        if (value) {
            this.$element.removeClass('panel_tree').addClass('panel_results');
            this.tree.setNavigationActive(false);
            this.setNavigationActive(true);
        } else {
            this.$element.addClass('panel_tree').removeClass('panel_results');
            this.tree.setNavigationActive(true);
            this.setNavigationActive(false);
        }
        if (value != this.lastQuery) {
            this.lastQuery = value;
            this.firstRun = true;
            this.searcher.find(value);
        }
    }

    this.addResults = function(results, isLast) {
        var target = this.$result.get(0);
        if (this.firstRun && (results.length > 0 || isLast)) {
            this.$current = null;
            this.$result.empty();
        }
        for (var i=0, l = results.length; i < l; i++) {
            target.appendChild(renderItem.call(this, results[i]));
        };
        if (this.firstRun && results.length > 0) {
            this.firstRun = false;
            this.$current = $(target.firstChild);
            this.$current.addClass('current');
            if (this.selectFirstMatch) this.select();
            scrollIntoView(this.$current[0], this.$view[0])
        }
        if (jQuery.browser.msie) this.$element[0].className += '';
    }

    this.open = function(src) {
        this.frame.location.href = '../' + src;
        if (this.frame.highlight) this.frame.highlight(src);
    }

    this.select = function() {
        this.open(this.$current.data('path'));
    }

    this.move = function(isDown) {
        if (!this.$current) return;
        var $next = this.$current[isDown ? 'next' : 'prev']();
        if ($next.length) {
            this.$current.removeClass('current');
            $next.addClass('current');
            scrollIntoView($next[0], this.$view[0]);
            this.$current = $next;
        }
        return true;
    }

    function renderItem(result) {
        var li = document.createElement('li'),
            html = '', badge = result.badge;
        html += '<h1>' + hlt(result.title);
        if (result.params) html += '<i>' + result.params + '</i>';
        html += '</h1>';
        html += '<p>';
        if (typeof badge != 'undefined') {
            html += '<span class="badge badge_' + (badge % 6 + 1) + '">' + escapeHTML(this.data.badges[badge] || 'unknown') + '</span>';
        }
        html += hlt(result.namespace) + '</p>';
        if (result.snippet) html += '<p class="snippet">' + escapeHTML(result.snippet) + '</p>';
        li.innerHTML = html;
        jQuery.data(li, 'path', result.path);
        return li;
    }

    function hlt(html) {
        return escapeHTML(html).replace(/\u0001/g, '<b>').replace(/\u0002/g, '</b>')
    }

    function escapeHTML(html) {
        return html.replace(/[&<>]/g, function(c) {
            return '&#' + c.charCodeAt(0) + ';';
        });
    }

}); 

// tree.js ------------------------------------------------

Searchdoc.Tree = function(element, tree, panel) {
    this.$element = $(element);
    this.$list = $('ul', element);
    this.tree = tree;
    this.panel = panel;
    this.init();
}

Searchdoc.Tree.prototype = $.extend({}, Searchdoc.Navigation, new function() {
    this.init = function() {
        var stopper = document.createElement('li');
        stopper.className = 'stopper';
        this.$list[0].appendChild(stopper);
        for (var i=0, l = this.tree.length; i < l; i++) {
            buildAndAppendItem.call(this, this.tree[i], 0, stopper);
        };
        var _this = this;
        this.$list.click(function(e) {
            var $target = $(e.target),
                $li = $target.closest('li');
            if ($target.hasClass('icon')) {
                _this.toggle($li);
            } else {
                _this.select($li);
            }
        })
        
        this.initNavigation();
        if (jQuery.browser.msie) document.body.className += '';
    }

    this.select = function($li) {
        this.highlight($li);
        var path = $li[0].searchdoc_tree_data.path;
        if (path) this.panel.open(path);
    }
    
    this.highlight = function($li) {
        if (this.$current) this.$current.removeClass('current');
        this.$current = $li.addClass('current');
    }

    this.toggle = function($li) {
        var closed = !$li.hasClass('closed'),
            children = $li[0].searchdoc_tree_data.children;
        $li.toggleClass('closed');
        for (var i=0, l = children.length; i < l; i++) {
            toggleVis.call(this, $(children[i].li), !closed);
        };
    }

    this.moveRight = function() {
        if (!this.$current) {
            this.highlight(this.$list.find('li:first'));
            return;
        }
        if (this.$current.hasClass('closed')) {
            this.toggle(this.$current);
        }
    }
    
    this.moveLeft = function() {
        if (!this.$current) {
            this.highlight(this.$list.find('li:first'));
            return;
        }
        if (!this.$current.hasClass('closed')) {
            this.toggle(this.$current);
        } else {
            var level = this.$current[0].searchdoc_tree_data.level;
            if (level == 0) return;
            var $next = this.$current.prevAll('li.level_' + (level - 1) + ':visible:first');
            this.$current.removeClass('current');
            $next.addClass('current');
            scrollIntoView($next[0], this.$element[0]);
            this.$current = $next;
        }
    }

    this.move = function(isDown) {
        if (!this.$current) {
            this.highlight(this.$list.find('li:first'));
            return true;
        }        
        var next = this.$current[0];
        if (isDown) {
            do {
                next = next.nextSibling;
                if (next && next.style && next.style.display != 'none') break;
            } while(next);
        } else {
            do {
                next = next.previousSibling;
                if (next && next.style && next.style.display != 'none') break;
            } while(next);
        }
        if (next && next.className.indexOf('stopper') == -1) {
            this.$current.removeClass('current');
            $(next).addClass('current');
            scrollIntoView(next, this.$element[0]);
            this.$current = $(next);
        }
        return true;
    }

    function toggleVis($li, show) {
        var closed = $li.hasClass('closed'),
            children = $li[0].searchdoc_tree_data.children;
        $li.css('display', show ? '' : 'none')
        if (!show && this.$current && $li[0] == this.$current[0]) {
            this.$current.removeClass('current');
            this.$current = null;
        }
        for (var i=0, l = children.length; i < l; i++) {
            toggleVis.call(this, $(children[i].li), show && !closed);
        };
    }

    function buildAndAppendItem(item, level, before) {
        var li   = renderItem(item, level),
            list = this.$list[0];
        item.li = li;
        list.insertBefore(li, before);
        for (var i=0, l = item[3].length; i < l; i++) {
            buildAndAppendItem.call(this, item[3][i], level + 1, before);
        };
        return li;
    }

    function renderItem(item, level) {
        var li = document.createElement('li'),
            cnt = document.createElement('div'),
            h1 = document.createElement('h1'),
            p = document.createElement('p'),
            icon, i;
        
        li.appendChild(cnt);
        li.style.paddingLeft = getOffset(level);
        cnt.className = 'content';
        if (!item[1]) li.className  = 'empty ';
        cnt.appendChild(h1);
        // cnt.appendChild(p);
        h1.appendChild(document.createTextNode(item[0]));
        // p.appendChild(document.createTextNode(item[4]));
        if (item[2]) {
            i = document.createElement('i');
            i.appendChild(document.createTextNode(item[2]));
            h1.appendChild(i);
        }
        if (item[3].length > 0) {
            icon = document.createElement('div');
            icon.className = 'icon';
            cnt.appendChild(icon);
        }
        
        // user direct assignement instead of $()
        // it's 8x faster
        // $(li).data('path', item[1])
        //     .data('children', item[3])
        //     .data('level', level)
        //     .css('display', level == 0 ? '' : 'none')
        //     .addClass('level_' + level)
        //     .addClass('closed');
        li.searchdoc_tree_data = {
            path: item[1],
            children: item[3],
            level: level
        }
        li.style.display = level == 0 ? '' : 'none';
        li.className += 'level_' + level + ' closed';
        return li;
    }

    function getOffset(level) {
        return 5 + 18*level + 'px';
    }
});    
