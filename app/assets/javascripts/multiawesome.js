//= require sifter

/**
 * multiawesome.js (v0.12.1)
 * Copyright (c) 2015 Jacob Schatz & contributors
 *
 * Licensed under the Apache License, Version 2.0 (the "License"); you may not use this
 * file except in compliance with the License. You may obtain a copy of the License at:
 * http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software distributed under
 * the License is distributed on an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF
 * ANY KIND, either express or implied. See the License for the specific language
 * governing permissions and limitations under the License.
 *
 * @author Jacob Schatz <jschatz@gitlab.com>
 */

/*jshint curly:false */
/*jshint browser:true */
(function ( $ ) {
  'use strict';

  var defaults = {
    data: [],
    title: '',
    tip: '',
    name: 'multi-awesome',
    header: [],
    multiple: false,
    alwaysPrefixWithSearch: false,
    placeholder: 'Filter...',
    onChange: function(){},
    always: [],
    dataObject: {
      label: 'label',
      data: 'data',
      category: 'category',
      subtitle: 'subtitle',
      image: 'image'
    },
    minSearchLength: 2
  };

  $.fn.multiawesome = function( options ) {
    var MultiAwesome = {
      extraMenuContainerTemplate: '<li data-extra-menu-container class="dropdown-multi-menu-extras-container"></li>',
      searchTemplate: '<li class="dropdown-multi-menu-search-container"><div class="input-with-icon"><i class="fa fa-search"></i><input type="text" id="multiawesome-search-input" /></div></li>',
      itemContainerTemplate: '<li class="dropdown-multi-menu-selections"><ul></ul></li>',
      itemTemplate: '<li><a href="#" class="item" data-item-selectable tabIndex="-1"><input type="checkbox" name="{{name}}" value="{{data}}"/>{{label}}</a></li>',
      seperatorTemplate: '<li role="separator" class="divider"></li>',
      headerTemplate: '<li class="dropdown-multi-menu-header"><div class="dropdown-multi-menu-header-area"><ul class="dropdown-multi-menu-header-list">{{header}}</ul></div></li>',
      headerItemTemplate: '<li class="dropdown-multi-menu-header-item"><a href="#" data-header-selectable class="header-item" tabIndex="-1"><input name="{{name}}" type="checkbox" value="{{data}}" />{{headeritem}}</a></li>',
      titleTemplate: '<li class="dropdown-multi-menu-title"><div class="dropdown-multi-menu-title-area"><a href="#" data-back-button class="dropdown-multi-menu-back-button"></a><h3 class="dropdown-multi-menu-title-text">{{title}}</h3></div></li>',
      categoryContainerTemplate: '<li class="dropdown-multi-menu-category"><ul></ul></li>',
      categoryItemTemplate: '<li><a href="#" class="category" data-category-selectable tabIndex="-1"><input type="checkbox" value="{{category}}"/>{{category}}</a></li>',
      tipTemplate: '<li class="dropdown-multi-menu-tip"><div class="dropdown-multi-menu-tip-area"><p>{{tip}}</p></div></li>',
      subtitleTemplate: '<p class="dropdown-multi-menu-subtitle">{{subtitle}}</p>',
      imageTemplate: '<div class="dropdown-multi-menu-image" style="background-image:url(\'{{image}}\');"></div>'
    };


    return this.each(function() {
      var self = this,
          categories = [],
          $self = $(self),
          $form = $(self).closest('form'),
          $itemContainer,
          $itemContainerUL,
          $extraMenuContainer,
          categoriesAppended = false,
          categoriesSet = false,
          selectedItems = [],
          selectedCategories = [],
          $searchInput,
          $extraMenus,
          $addedMenu,
          $backButton,
          $currentMenu,
          toHideForExtraMenus = [],
          sifter,
          
          // Merge the options and defaults into the settings. 
          // No need to check for undefined
          settings = $.extend(true, {}, defaults, options, $self.data());

      if( self.tagName !== 'UL') {
        return;
      }

      var prepareDropdown = function() {
        var $searchTemplate = $(MultiAwesome.searchTemplate);
        toHideForExtraMenus.push($searchTemplate);
        $self.prepend($searchTemplate);
        $searchInput = $searchTemplate.find('input');
        if( settings.placeholder ) {
          $searchInput.prop( 'placeholder', settings.placeholder );
        }
      };

      var attachListeners = function() {
        $self.on( 'click', '[data-category-selectable]' , dropdownCategoryLinkClicked );
        $self.on( 'click', 
          '[data-item-selectable], [data-header-selectable]', dropdownSelectionLinkClicked );
        $self.on( 'click', dropdownClickedAnywhere );
        $self.on( 'click', $backButton, backButtonClicked );
        $searchInput.on( 'keydown keyup update', inputSearched );
      };

      var parseSearchResults = function(results) {
        var finalData = [];
        results.forEach( function( result ) {
          finalData.push(settings.data[result.id]);
        });
        renderData( finalData );
      };

      var addCategories = function() {
        var $categoryContainer = $(MultiAwesome.categoryContainerTemplate);
        var $categoryContainerUL = $categoryContainer.find('ul');
        if( categories.length ) {
          var $seperatorTemplate = $(MultiAwesome.seperatorTemplate);
          toHideForExtraMenus.push($seperatorTemplate);
          $self.prepend($seperatorTemplate);
          categories.forEach(function( category ) {
            $categoryContainerUL.prepend( MultiAwesome.categoryItemTemplate
              .replace( /\{\{category\}\}/g, category ) );
          });
          $self.prepend($categoryContainer);
        }
      };

      var addTitle = function() {
        var titleTemplate;
        if( settings.title ) {
          var $seperatorTemplate = $(MultiAwesome.seperatorTemplate);
          var $titleTemplate = $(MultiAwesome.titleTemplate);
          $self.prepend($seperatorTemplate);
          $self.prepend(MultiAwesome.titleTemplate
            .replace(/\{\{title\}\}/g, settings.title)
          );
          $backButton = $self.find('[data-back-button]');

        }
      };

      var addExtrasContainer = function() {
        $extraMenuContainer = $(MultiAwesome.extraMenuContainerTemplate);
        $self.prepend($extraMenuContainer);
      };

      var addHeader = function() {
        var $headerTemplate,
            headerList = [];
        // if we have some header data
        if( settings.header.length ) {
          settings.header.forEach( function(item) {
            headerList.push(
              MultiAwesome.headerItemTemplate
                .replace(/\{\{headeritem\}\}/g, item[settings.dataObject.label])
                .replace(/\{\{data\}\}/g, item[settings.dataObject.data])
                .replace(/\{\{name\}\}/g, '_' + settings.name)
            );
          });
          var $seperatorTemplate = $(MultiAwesome.seperatorTemplate);
          toHideForExtraMenus.push($seperatorTemplate);
          $self.prepend($seperatorTemplate);
          $headerTemplate = $(MultiAwesome.headerTemplate.replace(/\{\{header\}\}/g, headerList.join('')));
          toHideForExtraMenus.push($headerTemplate);
          $self.prepend($headerTemplate);
        }
      };

      var addData = function(callback) {
        function parseDataWhenReady() {
          $itemContainer = $(MultiAwesome.itemContainerTemplate);
          toHideForExtraMenus.push($itemContainer);
          $itemContainerUL = $itemContainer.find('ul');

          sifter = new Sifter(settings.data);
          renderData( settings.data,callback );
        }
        if ( settings.data ) {
          if ( typeof settings.data === 'string') {
            $.getJSON(settings.data, function(data) {
              settings.data = data;
              parseDataWhenReady();
            });
          } else if ( typeof settings.data === 'object' ) {
            parseDataWhenReady();
          } else {
            $.error('Data must be a string or array');
          }
        }
      };

      var renderData = function( data, callback ) {
        selectedItems = [];
        $itemContainerUL.empty();
        var emptyObj = {},
          skipMatch = false,
          searchInputVal = [],
          o,
          tempAlwaysData = [],
          tempItemTemplate,
          $itemTemplate;
        
        if( !data.length ) {
          emptyObj[settings.dataObject.label] = 'No matches found';
          emptyObj[settings.dataObject.data] = 'dropdown-multi-menu-selectable:false';
          emptyObj[settings.dataObject.category] = '';
          emptyObj.selectable = false;
          data.push(emptyObj);
          skipMatch = true;
        }
        
        if( settings.alwaysPrefixWithSearch && $searchInput ) {
          searchInputVal = $searchInput.val();
          tempAlwaysData = settings.always.map(function(item){
            // copy, don't alter real object.
            o = $.extend({}, item);
            if(searchInputVal.length){
              o.label = '<strong>"' + searchInputVal + '"</strong>' + ' ' + o.label;  
            }
            
            o.always = true;
            return o;
          });
        } else {
          tempAlwaysData = settings.always;
        }
        data = data.concat(tempAlwaysData);
        data.forEach( function( item ) {
          tempItemTemplate = MultiAwesome.itemTemplate;
          if( !categoriesSet && !skipMatch ) {
            var addCategory = item[settings.dataObject.category];
            if( item.hasOwnProperty( settings.dataObject.category ) && categories.indexOf( addCategory ) === -1 ) {
              categories.push( addCategory );
            }
          } else {
            // only do this if the categories are already set... they won't search categories on the first time.
            if( selectedCategories.length && 
                selectedCategories.indexOf(item[settings.dataObject.category]) === -1 &&
                !skipMatch) {
              return;
            }
          }

          $itemTemplate = $(MultiAwesome.itemTemplate);

          if( item.hasOwnProperty('selectable') && !item.selectable ) {
            tempItemTemplate = $itemTemplate
              .find('a')
              .addClass('disabled')
              .find('input[type="checkbox"]')
              .prop('disabled','disabled')
              // back to the anchor tag
              .end()
              // back to the li
              .end()
              .get(0)
              .outerHTML;
          }

          if( item.hasOwnProperty( settings.dataObject.subtitle ) && 
              item[settings.dataObject.subtitle].length ) {
            tempItemTemplate = $(tempItemTemplate)
              .find('a')
              .addClass('dropdown-multi-menu-item-with-subtitle')
              .append(
                MultiAwesome.subtitleTemplate
                  .replace(/\{\{subtitle\}\}/g, item[settings.dataObject.subtitle])
              )
              .end()
              .get(0)
              .outerHTML;
          }

          if( item.hasOwnProperty( settings.dataObject.image ) &&
              item[settings.dataObject.image].length ) {
            tempItemTemplate = $(tempItemTemplate)
              .find('a')
              .addClass('dropdown-multi-menu-with-image')
              .prepend(
                MultiAwesome.imageTemplate
                  .replace(/\{\{image\}\}/g, item[settings.dataObject.image])
              )
              .end()
              .get(0)
              .outerHTML;
          }
          
          $itemContainerUL.append(
            tempItemTemplate
              .replace(/\{\{data\}\}/g,item[settings.dataObject.data])
              .replace(/\{\{label\}\}/g,item[settings.dataObject.label])
              .replace(/\{\{name\}\}/g, '_' + settings.name)
            );
        });
        if( !categoriesSet  && !categoriesAppended ) {
          $self.append($itemContainer);
          categoriesAppended = true;
        }

        if( categories.length ){
          categoriesSet = true;  
        }

        if( callback ) {
          callback();
        }
      };

      var addToForm = function( val ) {
        $form.prepend('<input type="hidden" name="' + settings.name + '" value="' + val + '" />');
      };

      var removeFromForm = function( val ) {
        $form
          .find('input[name="' + settings.name + '"][value="' + val + '"]')
          .remove();
      };

      var getExtraMenus = function() {
        $extraMenus = $self
        // get parent button group
        .closest('div.button-group')
        // get the extra menu divs
        .find('[data-extra-menu]');
      };

      /* * * * * * * * * * * * * * * */
      /* listeners
      /* * * * * * * * * * * * * * * */

      var backButtonClicked = function() {
        toHideForExtraMenus.forEach(function(menuSection){
          menuSection.show();
        });
        $extraMenuContainer.empty();
        $backButton.hide();
        return false;
      };

      var inputSearched = function() {

        //remove current hidden inputs
        $('input[type="hidden"][name="' + settings.name + '"]').remove();

        if( $searchInput.val().length > settings.minSearchLength ) {
          var results = sifter.search($searchInput.val(), {
            fields: [settings.dataObject.label],
            sort: [{field: settings.dataObject.label, direction: 'asc'}]
          });
          parseSearchResults(results.items);
        } else {
          renderData( settings.data );
        }
      };

      var moveToExtraMenu = function($menu) {
        var $cloneMenu = $menu.clone();
        toHideForExtraMenus.forEach(function(menuSection){
          menuSection.hide();
        });
        $currentMenu = $menu;
        $extraMenuContainer.append($cloneMenu);
        $cloneMenu.show();
        $backButton.show();
      };

      var isExtraMenuValue = function( val ) {
        var isMatch = false;
        $extraMenus.each( function() {
          var $this = $(this);
          if(val === $this.data('menu-target-value')) {
            isMatch = true;
            moveToExtraMenu($this);
            return;
          }
        });
        return isMatch;
      };

      var dropdownClickedAnywhere = function( e ) {};

      var dropdownCategoryLinkClicked = function ( e ) {
        var $target = $( e.currentTarget ),
            $inp = $target.find( 'input' ),
            val = $inp.val(),
            i = selectedCategories.indexOf( val );

        e.preventDefault();
        // if the checkbox is disabled.
        if( $inp.prop('disabled') ) {
          return false;
        }
        if ( i > -1 ) {
          var spliced = selectedCategories.splice( i, 1 );
          $target.removeClass('selected');
          setTimeout( function() { 
            $inp.prop( 'checked', false );
          }, 0);
        } else {
          selectedCategories.push( val );
          $target.addClass('selected');
          setTimeout( function() { 
            $inp.prop( 'checked', true );
          }, 0);
        }

        inputSearched();

        $( e.target ).blur();
        return false;
      };

      var findItemWithData = function(searchData, id) {
        var item = {};
        for (var i = searchData.length - 1; i >= 0; i--) {
          item = searchData[i];
          if( item.hasOwnProperty(settings.dataObject.data) && 
              item[settings.dataObject.data] == id ) {
            return item;
          }
        }
        return undefined;
      };

      var dropdownSelectionLinkClicked = function ( e ) {
        var $target = $( e.currentTarget ),
            $inp = $target.find( 'input' ),
            findItemInData,
            val = $inp.val(),
            i = selectedItems.indexOf( val );

        e.preventDefault();

        if( $inp.prop('disabled') ) {
          return false;
        }

        if( isExtraMenuValue( val ) ) {
          return false;
        }

        findItemInData = findItemWithData(settings.data, val);
        if( typeof findItemInData === 'undefined' ) {
          findItemInData = findItemWithData(settings.always, val);
        }

        if( typeof findItemInData === 'undefined' ) {
          findItemInData = findItemWithData(settings.header, val);
        }

        if( typeof findItemInData === 'undefined' && 
          val === 'dropdown-multi-menu-selectable:false' ) {
          // don't close the dropdown.
          return false;
        }

        if ( typeof findItemInData !== 'undefined' &&
              findItemInData.hasOwnProperty('selectable') && 
              findItemInData.selectable === false ) {
          // don't close the dropdown
          return false;
        }
        
        if( findItemInData.hasOwnProperty( 'href' ) ) {
          window.location.href = findItemInData.href;
          return;
        }

        if( findItemInData.hasOwnProperty('selectable') && 
            !findItemWithData.selectable ) {
          return;
        }


        if ( i > -1 ) {
          var spliced = selectedItems.splice( i, 1 );
          if( settings.multiple ) {
            removeFromForm( spliced );  
          } else {
            $form
              .find('input[name="' + settings.name + '"]')
              .remove();
          }
          
          $target.removeClass('selected');
          setTimeout( function() { 
            $inp.prop( 'checked', false );
          }, 0);
        } else {
          if( !settings.multiple ) {
            selectedItems = [];
            $form
              .find('input[name="' + settings.name + '"]')
              .remove();
            $form
              .find('input[name="_' + settings.name + '"]')
              .parent()
              .removeClass('selected');
          }

          selectedItems.push( val );
          addToForm( val );
          $target.addClass('selected');
          setTimeout( function() { 
            $inp.prop( 'checked', true );
          }, 0);
        }
        settings.onChange({"changed":findItemInData, "selected":selectedItems});
        // close the dropdown if single selection
        // otherwise don't close the dropdown
        if( settings.multiple ) {
          $( e.target ).blur();
          return false; 
        } else {
          var button = $self.siblings('.dropdown-toggle').first();
            button.contents()
            .each(
              function(){
                if ( this.nodeType === 3 && this.nodeValue.trim() ) {
                  this.textContent = $target.text();
                }
              });
        }
      };

      var addTip = function() {
        var $tipTemplate;
        if( settings.tip ) {
          var $seperatorTemplate = $(MultiAwesome.seperatorTemplate);
          toHideForExtraMenus.push($seperatorTemplate);
          $self.append($seperatorTemplate);
          $tipTemplate = $(MultiAwesome.tipTemplate.replace(/\{\{tip\}\}/g, settings.tip));
          toHideForExtraMenus.push($tipTemplate);
          $self.append($tipTemplate);
        }
      };

      /* * * * * * * * * * * * * * * */
      /* setup
      /* * * * * * * * * * * * * * * */

      var shouldInit = function() {
        if(!$self.hasClass('initialized')) {
          $self.addClass('initialized');
          return true;
        }
        return false;
      };

      var setup = function() {
        if(!shouldInit()){
          return;
        }
        addData(function(){
          addHeader();
          addCategories();
          prepareDropdown();
          addExtrasContainer();
          addTitle();
          attachListeners();
          addTip();
          getExtraMenus();
        });
      };

      setup();

    });
  };

  $(function(){

    $('[data-multi-awesome]').each(function(){
      $(this).multiawesome();
    });

  });
})( jQuery );