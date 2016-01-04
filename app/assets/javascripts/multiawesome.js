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
  $.fn.multiawesome = function( settings ) {
    settings = settings || {};
    var MultiAwesome = {
      searchTemplate: '<li><div class="input-with-icon"><i class="fa fa-search"></i><input type="text" id="multiawesome-search-input" /></div></li>',
      itemContainerTemplate: '<li class="dropdown-multi-menu-selections"><ul></ul></li>',
      itemTemplate: '<li><a href="#" class="item" tabIndex="-1"><input type="checkbox" name="{{name}}" value="{{data}}"/>{{label}}</a></li>',
      seperatorTemplate: '<li role="separator" class="divider"></li>',
      titleTemplate: '<li class=dropdown-multi-menu-title><div class=dropdown-multi-menu-title-area><h3>{{title}}</h3></div></li>',
      categoryContainerTemplate: '<li class=dropdown-multi-menu-category><ul></ul></li>',
      categoryItemTemplate: '<li><a href="#" class="category" tabIndex="-1"><input type="checkbox" value="{{category}}"/>{{category}}</a></li>',
      tipTemplate: '<li class=dropdown-multi-menu-tip><div class=dropdown-multi-menu-tip-area><p>{{tip}}</p></div></li>',
      minSearchLength: 2
    };


    return this.each(function() {
      var self = this,
          categories = [],
          $self = $(self),
          $form = $(self).closest('form'),
          $itemContainer,
          $itemContainerUL,
          itemTemplate,
          itemContainerTemplate,
          categoriesSet = false,
          selectedItems = [],
          selectedCategories = [],
          $searchInput,
          onChange = settings.onChange || function(){},
          multiple = typeof $self.attr('data-multiple') !== 'undefined',
          currentData = settings.data || $self.data('data'),
          inputName = $(self).data('name'),
          sifter,
          alwaysData = settings.always || [],
          dataObject = {
            label: 'label',
            data: 'data',
            category: 'category'
          };

      if( self.tagName !== 'UL') {
        return;
      }

      var prepareDropdown = function() {
        var placeholder = $self.data('placeholder');
        if( typeof settings.searchTemplate !== 'undefined' ) {
          MultiAwesome.searchTemplate = settings.searchTemplate;
        }

        $self.prepend(MultiAwesome.searchTemplate);
        if( placeholder ) {
          $('#multiawesome-search-input').prop( 'placeholder', placeholder );
        }
      };

      var attachBtnListeners = function() {
        $( 'ul.dropdown-multi-menu' ).on( 'click', 'li.dropdown-multi-menu-category a' , dropdownCategoryLinkClicked );
        $( 'ul.dropdown-multi-menu' ).on( 'click', 'li.dropdown-multi-menu-selections a', dropdownSelectionLinkClicked );
        $searchInput = $('#multiawesome-search-input');
        $searchInput.on( 'keydown keyup update', inputSearched );
      };

      var parseSearchResults = function(results) {
        var finalData = [];
        results.forEach( function( result ) {
          finalData.push(currentData[result.id]);
        });
        renderData( finalData );
      };

      var inputSearched = function() {
        var minSearchLength = settings.minSearchLength || MultiAwesome.minSearchLength;

        //remove current hidden inputs
        $('input[type="hidden"][name="' + inputName + '"]').remove();

        if( $searchInput.val().length > minSearchLength ) {
          var results = sifter.search($searchInput.val(), {
            fields: [dataObject.label],
            sort: [{field: dataObject.label, direction: 'asc'}]
          });
          parseSearchResults(results.items);
        } else {
          renderData( currentData );
        }
      };

      var configureData = function() {
        if ( typeof settings.itemLabelTitle !== 'undefined' ) {
          dataObject.label = settings.itemLabelTitle;
        }

        if ( typeof settings.itemDataTitle !== 'undefined' ) {
          dataObject.data = settings.itemDataTitle;
        }

        if ( typeof settings.itemCategoryTitle !== 'undefined' ) {
          dataObject.category = settings.itemCategoryTitle;
        }
      };

      var addCategories = function() {
        var $categoryContainer;
        var $categoryContainerUL;
        if( categories.length ) {
          if( typeof settings.categoryContainerTemplate !== 'undefined' ) {
            $categoryContainer = $(settings.categoryContainerTemplate);
          } else {
            $categoryContainer = $(MultiAwesome.categoryContainerTemplate);
          }
          $categoryContainerUL = $categoryContainer.find('ul');
          $self.prepend(MultiAwesome.seperatorTemplate);
          categories.forEach(function( category ) {
            $categoryContainerUL.prepend( MultiAwesome.categoryItemTemplate
              .replace( /\{\{category\}\}/g, category ) );
          });
          $self.prepend($categoryContainer);
        }
      };

      var addTitle = function() {
        var titleTemplate;
        var titleData = $self.data('title') || settings.title;
        if( typeof titleData !== 'undefined') {
          if(typeof settings.titleTemplate !== 'undefined') {
            titleTemplate = settings.titleTemplate;
          } else {
            titleTemplate = MultiAwesome.titleTemplate;
          }
          $self.prepend(MultiAwesome.seperatorTemplate);
          $self.prepend(titleTemplate
            .replace(/\{\{title\}\}/g, titleData)
          );
        }
      };

      var addData = function(callback) {
        function parseDataWhenReady() {
          itemTemplate = MultiAwesome.itemTemplate;
          itemContainerTemplate = MultiAwesome.itemContainerTemplate; 
          if( typeof settings.itemTemplate !== 'undefined' ) {
            itemTemplate = settings.itemTemplate;
          }
          if( typeof settings.itemContainerTemplate !== 'undefined' ) {
            itemContainerTemplate = settings.itemContainerTemplate;
          }
          $itemContainer = $(itemContainerTemplate);
          $itemContainerUL = $itemContainer.find('ul');

          sifter = new Sifter(currentData);
          renderData( currentData,callback );
        }
        configureData();
        if ( typeof currentData !== 'undefined' ) {
          if ( typeof currentData === 'string') {
            $.getJSON(currentData, function(data) {
              currentData = data;
              parseDataWhenReady();
            });
          } else if ( typeof currentData === 'object' ) {
            parseDataWhenReady();
          }
        }
      };

      var renderData = function( data, callback ) {
        selectedItems = [];
        $itemContainerUL.empty();
        var emptyObj = {};
        var skipMatch = false;
        if( !data.length ) {
          emptyObj[dataObject.label] = 'No matches found';
          emptyObj[dataObject.data] = '';
          emptyObj[dataObject.category] = '';
          data.push(emptyObj);
          skipMatch = true;
        }
        data = data.concat(alwaysData);
        data.forEach( function( item ) {
          if( !categoriesSet && !skipMatch ) {
            var addCategory = item[dataObject.category];
            if( item.hasOwnProperty( dataObject.category ) && categories.indexOf( addCategory ) === -1 ) {
              categories.push( addCategory );
            }
          } else {
            // only do this if the categories are already set... they won't search categories on the first time.
            if( selectedCategories.length && 
                selectedCategories.indexOf(item[dataObject.category]) === -1 &&
                !skipMatch) {
              return;
            }
          }
          
          $itemContainerUL.append(
            itemTemplate
              .replace(/\{\{data\}\}/g,item[dataObject.data])
              .replace(/\{\{label\}\}/g,item[dataObject.label])
              .replace(/\{\{name\}\}/g, '_' + inputName)
            );
        });
        if( !categoriesSet ) {
          $self.append($itemContainer);  
        }

        if( categories.length ){
          categoriesSet = true;  
        }

        if( callback ) {
          callback();
        }
      };

      var addToForm = function( val ) {
        $form.prepend('<input type="hidden" name="' + inputName + '" value="' + val + '" />');
      };

      var removeFromForm = function( val ) {
        $form
          .find('input[name="' + inputName + '"][value="' + val + '"]')
          .remove();
      };

      /* * * * * * * * * * * * * * * */
      /* listeners
      /* * * * * * * * * * * * * * * */
      var dropdownInputClicked = function( e ) {
        return false;
      };

      var dropdownCategoryLinkClicked = function ( e ) {
        var $target = $( e.currentTarget ),
            $inp = $target.find( 'input' ),
            val = $inp.val(),
            i = selectedCategories.indexOf( val );

        e.preventDefault();

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
          if( item.hasOwnProperty(dataObject.data) && item[dataObject.data] == id ) {
            return item;
          }
        };
        return undefined;
      };

      var dropdownSelectionLinkClicked = function ( e ) {
        var $target = $( e.currentTarget ),
            $inp = $target.find( 'input' ),
            findItemInData,
            val = $inp.val(),
            i = selectedItems.indexOf( val );

        e.preventDefault();

        if ( i > -1 ) {
          var spliced = selectedItems.splice( i, 1 );
          if( multiple ) {
            removeFromForm( spliced );  
          } else {
            $form
              .find('input[name="' + inputName + '"]')
              .remove();
          }
          
          $target.removeClass('selected');
          setTimeout( function() { 
            $inp.prop( 'checked', false );
          }, 0);
        } else {
          if( !multiple ) {
            selectedItems = [];
            $form
              .find('input[name="' + inputName + '"]')
              .remove();
            $form
              .find('input[name="_' + inputName + '"]')
              .parent()
              .removeClass('selected');
          }
          findItemInData = findItemWithData(currentData, val);
          if( typeof findItemInData === 'undefined' ) {
            findItemInData = findItemWithData(alwaysData, val)
          }
          onChange(findItemInData);

          selectedItems.push( val );
          addToForm( val );
          $target.addClass('selected');
          setTimeout( function() { 
            $inp.prop( 'checked', true );
          }, 0);
        }
        if( multiple ) {
          // close the dropdown if single selection
          $( e.target ).blur();
          return false; 
        } else {
          var button = $self.prevAll('.dropdown-toggle');
          $self.prevAll('.dropdown-toggle')
            .contents()
            .each(
              function(){
                if ( this.nodeType === 3 && this.nodeValue.trim() ) {
                  this.textContent = $target.text();
                }
              });
        }
      };

      var addTip = function() {
        var tipTemplate;
        var tipData = $self.data('tip') || settings.tip;
        if( typeof tipData !== 'undefined') {
          if(typeof settings.tipTemplate !== 'undefined') {
            tipTemplate = settings.tipTemplate;
          } else {
            tipTemplate = MultiAwesome.tipTemplate;
          }
          $self.append(MultiAwesome.seperatorTemplate);
          $self.append(tipTemplate
            .replace(/\{\{tip\}\}/g, tipData)
          );
        }
      };

      /* * * * * * * * * * * * * * * */
      /* setup
      /* * * * * * * * * * * * * * * */

      var setup = function() {
        addData(function(){
          addCategories();
          prepareDropdown();
          addTitle();
          attachBtnListeners();
          addTip();  
        });
      };

      setup();

    });
  };
})( jQuery );