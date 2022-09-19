import { SELECTED_CLASS } from '~/filtered_search/droplab/constants';
import DropDown from '~/filtered_search/droplab/drop_down';
import utils from '~/filtered_search/droplab/utils';

describe('DropLab DropDown', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  describe('class constructor', () => {
    beforeEach(() => {
      jest.spyOn(DropDown.prototype, 'getItems').mockImplementation(() => {});
      jest.spyOn(DropDown.prototype, 'initTemplateString').mockImplementation(() => {});
      jest.spyOn(DropDown.prototype, 'addEvents').mockImplementation(() => {});

      testContext.list = { innerHTML: 'innerHTML' };
      testContext.dropdown = new DropDown(testContext.list);
    });

    it('sets the .hidden property to true', () => {
      expect(testContext.dropdown.hidden).toBe(true);
    });

    it('sets the .list property', () => {
      expect(testContext.dropdown.list).toBe(testContext.list);
    });

    it('calls .getItems', () => {
      expect(DropDown.prototype.getItems).toHaveBeenCalled();
    });

    it('calls .initTemplateString', () => {
      expect(DropDown.prototype.initTemplateString).toHaveBeenCalled();
    });

    it('calls .addEvents', () => {
      expect(DropDown.prototype.addEvents).toHaveBeenCalled();
    });

    it('sets the .initialState property to the .list.innerHTML', () => {
      expect(testContext.dropdown.initialState).toBe(testContext.list.innerHTML);
    });

    describe('if the list argument is a string', () => {
      beforeEach(() => {
        testContext.element = {};
        testContext.selector = '.selector';

        jest.spyOn(Document.prototype, 'querySelector').mockReturnValue(testContext.element);

        testContext.dropdown = new DropDown(testContext.selector);
      });

      it('calls .querySelector with the selector string', () => {
        expect(Document.prototype.querySelector).toHaveBeenCalledWith(testContext.selector);
      });

      it('sets the .list property element', () => {
        expect(testContext.dropdown.list).toBe(testContext.element);
      });
    });
  });

  describe('getItems', () => {
    beforeEach(() => {
      testContext.list = { querySelectorAll: () => {} };
      testContext.dropdown = { list: testContext.list };
      testContext.nodeList = [];

      jest.spyOn(testContext.list, 'querySelectorAll').mockReturnValue(testContext.nodeList);

      testContext.getItems = DropDown.prototype.getItems.call(testContext.dropdown);
    });

    it('calls .querySelectorAll with a list item query', () => {
      expect(testContext.list.querySelectorAll).toHaveBeenCalledWith('li');
    });

    it('sets the .items property to the returned list items', () => {
      expect(testContext.dropdown.items).toEqual(expect.any(Array));
    });

    it('returns the .items', () => {
      expect(testContext.getItems).toEqual(expect.any(Array));
    });
  });

  describe('initTemplateString', () => {
    beforeEach(() => {
      testContext.items = [{ outerHTML: '<a></a>' }, { outerHTML: '<img>' }];
      testContext.dropdown = { items: testContext.items };

      DropDown.prototype.initTemplateString.call(testContext.dropdown);
    });

    it('should set .templateString to the last items .outerHTML', () => {
      expect(testContext.dropdown.templateString).toBe(testContext.items[1].outerHTML);
    });

    it('should not set .templateString to a non-last items .outerHTML', () => {
      expect(testContext.dropdown.templateString).not.toBe(testContext.items[0].outerHTML);
    });

    describe('if .items is not set', () => {
      beforeEach(() => {
        testContext.dropdown = { getItems: () => {} };

        jest.spyOn(testContext.dropdown, 'getItems').mockReturnValue([]);

        DropDown.prototype.initTemplateString.call(testContext.dropdown);
      });

      it('should call .getItems', () => {
        expect(testContext.dropdown.getItems).toHaveBeenCalled();
      });
    });

    describe('if items array is empty', () => {
      beforeEach(() => {
        testContext.dropdown = { items: [] };

        DropDown.prototype.initTemplateString.call(testContext.dropdown);
      });

      it('should set .templateString to an empty string', () => {
        expect(testContext.dropdown.templateString).toBe('');
      });
    });
  });

  describe('clickEvent', () => {
    beforeEach(() => {
      testContext.classList = {
        contains: jest.fn(),
      };
      testContext.list = { dispatchEvent: () => {} };
      testContext.dropdown = {
        hideOnClick: true,
        hide: () => {},
        list: testContext.list,
        addSelectedClass: () => {},
      };
      testContext.event = {
        preventDefault: () => {},
        target: {
          classList: testContext.classList,
          closest: () => null,
        },
      };

      testContext.dummyListItem = document.createElement('li');
      jest.spyOn(testContext.event.target, 'closest').mockImplementation((selector) => {
        if (selector === 'li') {
          return testContext.dummyListItem;
        }

        return null;
      });

      jest.spyOn(testContext.dropdown, 'hide').mockImplementation(() => {});
      jest.spyOn(testContext.dropdown, 'addSelectedClass').mockImplementation(() => {});
      jest.spyOn(testContext.list, 'dispatchEvent').mockImplementation(() => {});
      jest.spyOn(testContext.event, 'preventDefault').mockImplementation(() => {});
      window.CustomEvent = jest.fn();
      testContext.classList.contains.mockReturnValue(false);
    });

    describe('normal click event', () => {
      beforeEach(() => {
        DropDown.prototype.clickEvent.call(testContext.dropdown, testContext.event);
      });
      it('should call event.target.closest', () => {
        expect(testContext.event.target.closest).toHaveBeenCalledWith('.droplab-item-ignore');
        expect(testContext.event.target.closest).toHaveBeenCalledWith('li');
      });

      it('should call addSelectedClass', () => {
        expect(testContext.dropdown.addSelectedClass).toHaveBeenCalledWith(
          testContext.dummyListItem,
        );
      });

      it('should call .preventDefault', () => {
        expect(testContext.event.preventDefault).toHaveBeenCalled();
      });

      it('should call .hide', () => {
        expect(testContext.dropdown.hide).toHaveBeenCalled();
      });

      it('should construct CustomEvent', () => {
        expect(window.CustomEvent).toHaveBeenCalledWith('click.dl', expect.any(Object));
      });

      it('should call .dispatchEvent with the customEvent', () => {
        expect(testContext.list.dispatchEvent).toHaveBeenCalledWith({});
      });
    });

    describe('if the target is a UL element', () => {
      beforeEach(() => {
        testContext.event.target = document.createElement('ul');

        jest.spyOn(testContext.event.target, 'closest').mockImplementation(() => {});
      });

      it('should return immediately', () => {
        DropDown.prototype.clickEvent.call(testContext.dropdown, testContext.event);

        expect(testContext.event.target.closest).not.toHaveBeenCalled();
        expect(testContext.dropdown.addSelectedClass).not.toHaveBeenCalled();
      });
    });

    describe('if the target has the droplab-item-ignore class', () => {
      beforeEach(() => {
        testContext.ignoredButton = document.createElement('button');
        testContext.ignoredButton.classList.add('droplab-item-ignore');
        testContext.event.target = testContext.ignoredButton;

        jest.spyOn(testContext.ignoredButton, 'closest');
      });

      it('does not select element', () => {
        DropDown.prototype.clickEvent.call(testContext.dropdown, testContext.event);

        expect(testContext.ignoredButton.closest.mock.calls.length).toBe(1);
        expect(testContext.ignoredButton.closest).toHaveBeenCalledWith('.droplab-item-ignore');
        expect(testContext.dropdown.addSelectedClass).not.toHaveBeenCalled();
      });
    });

    describe('if no selected element exists', () => {
      beforeEach(() => {
        testContext.event.preventDefault.mockReset();
        testContext.dummyListItem = null;
      });

      it('should return before .preventDefault is called', () => {
        DropDown.prototype.clickEvent.call(testContext.dropdown, testContext.event);

        expect(testContext.event.preventDefault).not.toHaveBeenCalled();
        expect(testContext.dropdown.addSelectedClass).not.toHaveBeenCalled();
      });
    });

    describe('if hideOnClick is false', () => {
      beforeEach(() => {
        testContext.dropdown.hideOnClick = false;
        testContext.dropdown.hide.mockReset();
      });

      it('should not call .hide', () => {
        DropDown.prototype.clickEvent.call(testContext.dropdown, testContext.event);

        expect(testContext.dropdown.hide).not.toHaveBeenCalled();
      });
    });
  });

  describe('addSelectedClass', () => {
    beforeEach(() => {
      testContext.items = Array(4).forEach((item, i) => {
        testContext.items[i] = { classList: { add: () => {} } };
        jest.spyOn(testContext.items[i].classList, 'add').mockImplementation(() => {});
      });
      testContext.selected = { classList: { add: () => {} } };
      testContext.dropdown = { removeSelectedClasses: () => {} };

      jest.spyOn(testContext.dropdown, 'removeSelectedClasses').mockImplementation(() => {});
      jest.spyOn(testContext.selected.classList, 'add').mockImplementation(() => {});

      DropDown.prototype.addSelectedClass.call(testContext.dropdown, testContext.selected);
    });

    it('should call .removeSelectedClasses', () => {
      expect(testContext.dropdown.removeSelectedClasses).toHaveBeenCalled();
    });

    it('should call .classList.add', () => {
      expect(testContext.selected.classList.add).toHaveBeenCalledWith(SELECTED_CLASS);
    });
  });

  describe('removeSelectedClasses', () => {
    beforeEach(() => {
      testContext.items = [...Array(4)];
      testContext.items.forEach((item, i) => {
        testContext.items[i] = { classList: { add: jest.fn(), remove: jest.fn() } };
      });
      testContext.dropdown = { items: testContext.items };

      DropDown.prototype.removeSelectedClasses.call(testContext.dropdown);
    });

    it('should call .classList.remove for all items', () => {
      testContext.items.forEach((_, i) => {
        expect(testContext.items[i].classList.remove).toHaveBeenCalledWith(SELECTED_CLASS);
      });
    });

    describe('if .items is not set', () => {
      beforeEach(() => {
        testContext.dropdown = { getItems: () => {} };

        jest.spyOn(testContext.dropdown, 'getItems').mockReturnValue([]);

        DropDown.prototype.removeSelectedClasses.call(testContext.dropdown);
      });

      it('should call .getItems', () => {
        expect(testContext.dropdown.getItems).toHaveBeenCalled();
      });
    });
  });

  describe('addEvents', () => {
    beforeEach(() => {
      testContext.list = {
        addEventListener: () => {},
        querySelectorAll: () => [],
      };
      testContext.dropdown = {
        list: testContext.list,
        clickEvent: () => {},
        closeDropdown: () => {},
        eventWrapper: {},
      };
    });

    it('should call .addEventListener', () => {
      jest.spyOn(testContext.list, 'addEventListener').mockImplementation(() => {});

      DropDown.prototype.addEvents.call(testContext.dropdown);

      expect(testContext.list.addEventListener).toHaveBeenCalledWith('click', expect.any(Function));
      expect(testContext.list.addEventListener).toHaveBeenCalledWith('keyup', expect.any(Function));
    });
  });

  describe('setData', () => {
    beforeEach(() => {
      testContext.dropdown = { render: () => {} };
      testContext.data = ['data'];

      jest.spyOn(testContext.dropdown, 'render').mockImplementation(() => {});

      DropDown.prototype.setData.call(testContext.dropdown, testContext.data);
    });

    it('should set .data', () => {
      expect(testContext.dropdown.data).toBe(testContext.data);
    });

    it('should call .render with the .data', () => {
      expect(testContext.dropdown.render).toHaveBeenCalledWith(testContext.data);
    });
  });

  describe('addData', () => {
    beforeEach(() => {
      testContext.dropdown = { render: () => {}, data: ['data1'] };
      testContext.data = ['data2'];

      jest.spyOn(testContext.dropdown, 'render').mockImplementation(() => {});
      jest.spyOn(Array.prototype, 'concat');

      DropDown.prototype.addData.call(testContext.dropdown, testContext.data);
    });

    it('should call .concat with data', () => {
      expect(Array.prototype.concat).toHaveBeenCalledWith(testContext.data);
    });

    it('should set .data with concatination', () => {
      expect(testContext.dropdown.data).toStrictEqual(['data1', 'data2']);
    });

    it('should call .render with the .data', () => {
      expect(testContext.dropdown.render).toHaveBeenCalledWith(['data1', 'data2']);
    });

    describe('if .data is undefined', () => {
      beforeEach(() => {
        testContext.dropdown = { render: () => {}, data: undefined };
        testContext.data = ['data2'];

        jest.spyOn(testContext.dropdown, 'render').mockImplementation(() => {});

        DropDown.prototype.addData.call(testContext.dropdown, testContext.data);
      });

      it('should set .data with concatination', () => {
        expect(testContext.dropdown.data).toStrictEqual(['data2']);
      });
    });
  });

  describe('render', () => {
    beforeEach(() => {
      testContext.renderableList = {};
      testContext.list = {
        querySelector: (q) => {
          if (q === '.filter-dropdown-loading') {
            return false;
          }
          return testContext.renderableList;
        },
        dispatchEvent: () => {},
      };
      testContext.dropdown = { renderChildren: () => {}, list: testContext.list };
      testContext.data = [0, 1];
      testContext.customEvent = {};

      jest.spyOn(testContext.dropdown, 'renderChildren').mockImplementation((data) => data);
      jest.spyOn(testContext.list, 'dispatchEvent').mockImplementation(() => {});
      jest.spyOn(testContext.data, 'map');
      jest.spyOn(window, 'CustomEvent').mockReturnValue(testContext.customEvent);

      DropDown.prototype.render.call(testContext.dropdown, testContext.data);
    });

    it('should call .map', () => {
      expect(testContext.data.map).toHaveBeenCalledWith(expect.any(Function));
    });

    it('should call .renderChildren for each data item', () => {
      expect(testContext.dropdown.renderChildren.mock.calls.length).toBe(testContext.data.length);
    });

    it('sets the renderableList .innerHTML', () => {
      expect(testContext.renderableList.innerHTML).toBe('01');
    });

    it('should call render.dl', () => {
      expect(window.CustomEvent).toHaveBeenCalledWith('render.dl', expect.any(Object));
    });

    it('should call dispatchEvent with the customEvent', () => {
      expect(testContext.list.dispatchEvent).toHaveBeenCalledWith(testContext.customEvent);
    });

    describe('if no data argument is passed', () => {
      beforeEach(() => {
        testContext.data.map.mockReset();
        testContext.dropdown.renderChildren.mockReset();

        DropDown.prototype.render.call(testContext.dropdown, undefined);
      });

      it('should not call .map', () => {
        expect(testContext.data.map).not.toHaveBeenCalled();
      });

      it('should not call .renderChildren', () => {
        expect(testContext.dropdown.renderChildren).not.toHaveBeenCalled();
      });
    });

    describe('if no dynamic list is present', () => {
      beforeEach(() => {
        testContext.list = { querySelector: () => {}, dispatchEvent: () => {} };
        testContext.dropdown = { renderChildren: () => {}, list: testContext.list };
        testContext.data = [0, 1];

        jest.spyOn(testContext.dropdown, 'renderChildren').mockImplementation((data) => data);
        jest.spyOn(testContext.list, 'querySelector').mockImplementation(() => {});
        jest.spyOn(testContext.data, 'map');

        DropDown.prototype.render.call(testContext.dropdown, testContext.data);
      });

      it('sets the .list .innerHTML', () => {
        expect(testContext.list.innerHTML).toBe('01');
      });
    });
  });

  describe('renderChildren', () => {
    beforeEach(() => {
      testContext.templateString = 'templateString';
      testContext.dropdown = { templateString: testContext.templateString };
      testContext.data = { droplab_hidden: true };
      testContext.html = 'html';
      testContext.template = { firstChild: { outerHTML: 'outerHTML', style: {} } };

      jest.spyOn(utils, 'template').mockReturnValue(testContext.html);
      jest.spyOn(document, 'createElement').mockReturnValue(testContext.template);
      jest.spyOn(DropDown, 'setImagesSrc').mockImplementation(() => {});

      testContext.renderChildren = DropDown.prototype.renderChildren.call(
        testContext.dropdown,
        testContext.data,
      );
    });

    it('should call utils.t with .templateString and data', () => {
      expect(utils.template).toHaveBeenCalledWith(testContext.templateString, testContext.data);
    });

    it('should call document.createElement', () => {
      expect(document.createElement).toHaveBeenCalledWith('div');
    });

    it('should set the templates .innerHTML to the HTML', () => {
      expect(testContext.template.innerHTML).toBe(testContext.html);
    });

    it('should call .setImagesSrc with the template', () => {
      expect(DropDown.setImagesSrc).toHaveBeenCalledWith(testContext.template);
    });

    it('should set the template display to none', () => {
      expect(testContext.template.firstChild.style.display).toBe('none');
    });

    it('should return the templates .firstChild.outerHTML', () => {
      expect(testContext.renderChildren).toBe(testContext.template.firstChild.outerHTML);
    });

    describe('if droplab_hidden is false', () => {
      beforeEach(() => {
        testContext.data = { droplab_hidden: false };
        testContext.renderChildren = DropDown.prototype.renderChildren.call(
          testContext.dropdown,
          testContext.data,
        );
      });

      it('should set the template display to block', () => {
        expect(testContext.template.firstChild.style.display).toBe('block');
      });
    });
  });

  describe('setImagesSrc', () => {
    beforeEach(() => {
      testContext.template = { querySelectorAll: () => {} };

      jest.spyOn(testContext.template, 'querySelectorAll').mockReturnValue([]);

      DropDown.setImagesSrc(testContext.template);
    });

    it('should call .querySelectorAll', () => {
      expect(testContext.template.querySelectorAll).toHaveBeenCalledWith('img[data-src]');
    });
  });

  describe('show', () => {
    beforeEach(() => {
      testContext.list = { style: {} };
      testContext.dropdown = { list: testContext.list, hidden: true };

      DropDown.prototype.show.call(testContext.dropdown);
    });

    it('should set .list display to block', () => {
      expect(testContext.list.style.display).toBe('block');
    });

    it('should set .hidden to false', () => {
      expect(testContext.dropdown.hidden).toBe(false);
    });

    describe('if .hidden is false', () => {
      beforeEach(() => {
        testContext.list = { style: {} };
        testContext.dropdown = { list: testContext.list, hidden: false };

        testContext.show = DropDown.prototype.show.call(testContext.dropdown);
      });

      it('should return undefined', () => {
        expect(testContext.show).toBeUndefined();
      });

      it('should not set .list display to block', () => {
        expect(testContext.list.style.display).not.toBe('block');
      });
    });
  });

  describe('hide', () => {
    beforeEach(() => {
      testContext.list = { style: {} };
      testContext.dropdown = { list: testContext.list };

      DropDown.prototype.hide.call(testContext.dropdown);
    });

    it('should set .list display to none', () => {
      expect(testContext.list.style.display).toBe('none');
    });

    it('should set .hidden to true', () => {
      expect(testContext.dropdown.hidden).toBe(true);
    });
  });

  describe('toggle', () => {
    beforeEach(() => {
      testContext.hidden = true;
      testContext.dropdown = { hidden: testContext.hidden, show: () => {}, hide: () => {} };

      jest.spyOn(testContext.dropdown, 'show').mockImplementation(() => {});
      jest.spyOn(testContext.dropdown, 'hide').mockImplementation(() => {});

      DropDown.prototype.toggle.call(testContext.dropdown);
    });

    it('should call .show', () => {
      expect(testContext.dropdown.show).toHaveBeenCalled();
    });

    describe('if .hidden is false', () => {
      beforeEach(() => {
        testContext.hidden = false;
        testContext.dropdown = { hidden: testContext.hidden, show: () => {}, hide: () => {} };

        jest.spyOn(testContext.dropdown, 'show').mockImplementation(() => {});
        jest.spyOn(testContext.dropdown, 'hide').mockImplementation(() => {});

        DropDown.prototype.toggle.call(testContext.dropdown);
      });

      it('should call .hide', () => {
        expect(testContext.dropdown.hide).toHaveBeenCalled();
      });
    });
  });

  describe('destroy', () => {
    beforeEach(() => {
      testContext.list = { removeEventListener: () => {} };
      testContext.eventWrapper = { clickEvent: 'clickEvent' };
      testContext.dropdown = {
        list: testContext.list,
        hide: () => {},
        eventWrapper: testContext.eventWrapper,
      };

      jest.spyOn(testContext.list, 'removeEventListener').mockImplementation(() => {});
      jest.spyOn(testContext.dropdown, 'hide').mockImplementation(() => {});

      DropDown.prototype.destroy.call(testContext.dropdown);
    });

    it('should call .hide', () => {
      expect(testContext.dropdown.hide).toHaveBeenCalled();
    });

    it('should call .removeEventListener', () => {
      expect(testContext.list.removeEventListener).toHaveBeenCalledWith(
        'click',
        testContext.eventWrapper.clickEvent,
      );
    });
  });
});
