import * as commonUtils from '~/lib/utils/common_utils';

describe('common_utils', () => {
  describe('getPagePath', () => {
    const { getPagePath } = commonUtils;

    let originalBody;

    beforeEach(() => {
      originalBody = document.body;
      document.body = document.createElement('body');
    });

    afterEach(() => {
      document.body = originalBody;
    });

    it('returns an empty path if none is defined', () => {
      expect(getPagePath()).toBe('');
      expect(getPagePath(0)).toBe('');
    });

    describe('returns a path', () => {
      const mockSection = 'my_section';
      const mockSubSection = 'my_sub_section';
      const mockPage = 'my_page';

      it('returns a page', () => {
        document.body.dataset.page = mockPage;

        expect(getPagePath()).toBe(mockPage);
        expect(getPagePath(0)).toBe(mockPage);
      });

      it('returns a section and page', () => {
        document.body.dataset.page = `${mockSection}:${mockPage}`;

        expect(getPagePath()).toBe(mockSection);
        expect(getPagePath(0)).toBe(mockSection);
        expect(getPagePath(1)).toBe(mockPage);
      });

      it('returns a section and subsection', () => {
        document.body.dataset.page = `${mockSection}:${mockSubSection}:${mockPage}`;

        expect(getPagePath()).toBe(mockSection);
        expect(getPagePath(0)).toBe(mockSection);
        expect(getPagePath(1)).toBe(mockSubSection);
        expect(getPagePath(2)).toBe(mockPage);
      });
    });
  });

  describe('handleLocationHash', () => {
    beforeEach(() => {
      jest.spyOn(window.document, 'getElementById');
    });

    afterEach(() => {
      window.history.pushState({}, null, '');
    });

    function expectGetElementIdToHaveBeenCalledWith(elementId) {
      expect(window.document.getElementById).toHaveBeenCalledWith(elementId);
    }

    it('decodes hash parameter', () => {
      window.history.pushState({}, null, '#random-hash');
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('random-hash');
      expectGetElementIdToHaveBeenCalledWith('user-content-random-hash');
    });

    it('decodes cyrillic hash parameter', () => {
      window.history.pushState({}, null, '#definição');
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('definição');
      expectGetElementIdToHaveBeenCalledWith('user-content-definição');
    });

    it('decodes encoded cyrillic hash parameter', () => {
      window.history.pushState({}, null, '#defini%C3%A7%C3%A3o');
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('definição');
      expectGetElementIdToHaveBeenCalledWith('user-content-definição');
    });

    it(`does not scroll when ${commonUtils.NO_SCROLL_TO_HASH_CLASS} is set on target`, () => {
      jest.spyOn(window, 'scrollBy');

      document.body.innerHTML += `
        <div id="parent">
          <a href="#test">Link</a>
          <div style="height: 2000px;"></div>
          <div id="test" style="height: 2000px;" class="${commonUtils.NO_SCROLL_TO_HASH_CLASS}"></div>
        </div>
      `;

      window.history.pushState({}, null, '#test');
      commonUtils.handleLocationHash();
      jest.runOnlyPendingTimers();

      try {
        expect(window.scrollBy).not.toHaveBeenCalled();
      } finally {
        document.getElementById('parent').remove();
      }
    });

    it('scrolls element into view', () => {
      document.body.innerHTML += `
        <div id="parent">
          <div style="height: 2000px;"></div>
          <div id="test" style="height: 2000px;"></div>
        </div>
      `;

      window.history.pushState({}, null, '#test');
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('test');

      expect(window.scrollY).toBe(document.getElementById('test').offsetTop);

      document.getElementById('parent').remove();
    });

    it('scrolls user content element into view', () => {
      document.body.innerHTML += `
        <div id="parent">
          <div style="height: 2000px;"></div>
          <div id="user-content-test" style="height: 2000px;"></div>
        </div>
      `;

      window.history.pushState({}, null, '#test');
      commonUtils.handleLocationHash();

      expectGetElementIdToHaveBeenCalledWith('test');
      expectGetElementIdToHaveBeenCalledWith('user-content-test');

      expect(window.scrollY).toBe(document.getElementById('user-content-test').offsetTop);

      document.getElementById('parent').remove();
    });

    it('scrolls to element with offset from navbar', () => {
      jest.spyOn(window, 'scrollBy');
      document.body.innerHTML += `
        <div id="parent">
          <div class="header-logged-out" style="position: fixed; top: 0; height: 50px;"></div>
          <div style="height: 2000px; margin-top: 50px;"></div>
          <div id="user-content-test" style="height: 2000px;"></div>
        </div>
      `;

      window.history.pushState({}, null, '#test');
      commonUtils.handleLocationHash();
      jest.advanceTimersByTime(1);

      expectGetElementIdToHaveBeenCalledWith('test');
      expectGetElementIdToHaveBeenCalledWith('user-content-test');

      expect(window.scrollY).toBe(document.getElementById('user-content-test').offsetTop - 50);
      expect(window.scrollBy).toHaveBeenCalledWith(0, -50);

      document.getElementById('parent').remove();
    });

    it('Scrolls element to correct height on issue page', () => {
      jest.spyOn(window, 'scrollBy');
      const stickyHeaderHeight = 50;
      const topPadding = 8;

      const expectedOffset = stickyHeaderHeight + topPadding;

      document.body.dataset.page = 'projects:issues:show';
      document.body.innerHTML += `
      <div id="parent">
        <div class="issue-sticky-header" style="position: fixed; top: 0px; height: ${stickyHeaderHeight}px;"></div>
        <div style="height: 2000px; margin-top: ${stickyHeaderHeight}px;"></div>
        <div id="user-content-test" style="height: 2000px;"></div>
      </div>
      `;
      window.history.pushState({}, null, '#test');
      commonUtils.handleLocationHash();
      jest.advanceTimersByTime(1);

      expectGetElementIdToHaveBeenCalledWith('test');
      expectGetElementIdToHaveBeenCalledWith('user-content-test');

      expect(window.scrollBy).toHaveBeenCalledWith(0, -1 * expectedOffset);

      document.getElementById('parent').remove();
    });

    it('Scrolls element to correct height on MR page', () => {
      jest.spyOn(window, 'scrollBy');
      const stickyHeaderHeight = 100;
      const fixedTabsHeight = 50;
      const topPadding = 8;

      const expectedOffset = stickyHeaderHeight + topPadding;

      document.body.dataset.page = 'projects:merge_requests:show';

      document.body.innerHTML += `
      <div id="parent">
        <div class="js-tabs-affix outer" style="height: ${fixedTabsHeight}px;"></div>
        <div class="merge-request-sticky-header" style="position: fixed; top: 0px; height: ${stickyHeaderHeight}px;">
          <div class="js-tabs-affix inner" style="height: ${fixedTabsHeight}px;"></div>
        </div>
        <div style="height: 2000px; margin-top: ${stickyHeaderHeight * 2}px;"></div>
        <div id="user-content-test" style="height: 2000px;"></div>
      </div>
      `;
      window.history.pushState({}, null, '#test');
      commonUtils.handleLocationHash();
      jest.advanceTimersByTime(1);

      expectGetElementIdToHaveBeenCalledWith('test');
      expectGetElementIdToHaveBeenCalledWith('user-content-test');

      expect(window.scrollBy).toHaveBeenCalledWith(0, -1 * expectedOffset);

      document.getElementById('parent').remove();
    });
  });

  describe('historyPushState', () => {
    afterEach(() => {
      window.history.replaceState({}, null, null);
    });

    it('should call pushState with the correct path', () => {
      jest.spyOn(window.history, 'pushState').mockImplementation(() => {});

      commonUtils.historyPushState('newpath?page=2');

      expect(window.history.pushState).toHaveBeenCalled();
      expect(window.history.pushState.mock.calls[0][2]).toContain('newpath?page=2');
    });
  });

  describe('buildUrlWithCurrentLocation', () => {
    it('should build an url with current location and given parameters', () => {
      expect(commonUtils.buildUrlWithCurrentLocation()).toEqual(window.location.pathname);
      expect(commonUtils.buildUrlWithCurrentLocation('?page=2')).toEqual(
        `${window.location.pathname}?page=2`,
      );
    });
  });

  describe('scrollToElement*', () => {
    let parentElem;
    let elem;
    const windowHeight = 550;
    const elemTop = 100;
    const parentId = 'parent_scroll_test';
    const id = 'scroll_test';

    beforeEach(() => {
      parentElem = document.createElement('div');
      parentElem.id = parentId;
      elem = document.createElement('div');
      elem.id = id;
      parentElem.appendChild(elem);
      document.body.appendChild(parentElem);

      window.innerHeight = windowHeight;
      window.mrTabs = { currentAction: 'show' };

      jest.spyOn(window, 'scrollTo').mockImplementation(() => {});
      jest.spyOn(parentElem, 'scrollTo').mockImplementation(() => {});
      jest.spyOn(Element.prototype, 'getBoundingClientRect').mockReturnValue({ top: elemTop });
    });

    afterEach(() => {
      window.scrollTo.mockRestore();
      parentElem.scrollTo.mockRestore();
      Element.prototype.getBoundingClientRect.mockRestore();
      elem.remove();
      parentElem.remove();
    });

    describe('scrollToElement with HTMLElement', () => {
      it('scrolls to element', () => {
        commonUtils.scrollToElement(elem);
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });

      it('scrolls to element with offset', () => {
        const offset = 50;
        commonUtils.scrollToElement(elem, { offset });
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop + offset,
        });
      });

      it('scrolls to element within a parent', () => {
        commonUtils.scrollToElement(elem, { parent: parentElem });
        expect(parentElem.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });
    });

    describe('scrollToElement with Selector', () => {
      it('scrolls to element', () => {
        commonUtils.scrollToElement(`#${id}`);
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });

      it('scrolls to element with offset', () => {
        const offset = 50;
        commonUtils.scrollToElement(`#${id}`, { offset });
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop + offset,
        });
      });

      it('scrolls to element within a parent', () => {
        commonUtils.scrollToElement(`#${id}`, { parent: `#${parentId}` });
        expect(parentElem.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elemTop,
        });
      });
    });

    describe('scrollToElementWithContext', () => {
      // This is what the implementation of scrollToElementWithContext
      // scrolls to, in case we change tha implementation
      // it needs to be adjusted
      const elementTopWithContext = elemTop - windowHeight * 0.1;

      it('with HTMLElement scrolls with context', () => {
        commonUtils.scrollToElementWithContext(elem);
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elementTopWithContext,
        });
      });

      it('with Selector scrolls with context', () => {
        commonUtils.scrollToElementWithContext(`#${id}`);
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elementTopWithContext,
        });
      });

      it('passes through behaviour', () => {
        commonUtils.scrollToElementWithContext(`#${id}`, { behavior: 'smooth' });
        expect(window.scrollTo).toHaveBeenCalledWith({
          behavior: 'smooth',
          top: elementTopWithContext,
        });
      });
    });
  });

  describe('debounceByAnimationFrame', () => {
    it('debounces a function to allow a maximum of one call per animation frame', () => {
      const spy = jest.fn();
      const debouncedSpy = commonUtils.debounceByAnimationFrame(spy);

      debouncedSpy();
      debouncedSpy();
      jest.runOnlyPendingTimers();

      expect(spy).toHaveBeenCalledTimes(1);
    });
  });

  describe('insertText', () => {
    let textArea;

    beforeEach(() => {
      textArea = document.createElement('textarea');
      document.querySelector('body').appendChild(textArea);
      textArea.value = 'two';
      textArea.setSelectionRange(0, 0);
      textArea.focus();
    });

    describe('using execCommand', () => {
      beforeAll(() => {
        document.execCommand = jest.fn(() => true);
      });

      it('inserts the text', () => {
        commonUtils.insertText(textArea, 'one');

        expect(document.execCommand).toHaveBeenCalledWith('insertText', false, 'one');
      });

      it('removes selected text', () => {
        textArea.setSelectionRange(0, textArea.value.length);

        commonUtils.insertText(textArea, '');

        expect(document.execCommand).toHaveBeenCalledWith('delete');
      });

      // It's not clear when this actually happens but it has been observed
      // in the wild. Probably related to the very large `insertMarkdownText` function.
      it('does nothing if no selection', () => {
        commonUtils.insertText(textArea, '');

        expect(document.execCommand).not.toHaveBeenCalled();
      });
    });

    describe('using fallback', () => {
      beforeEach(() => {
        document.execCommand = jest.fn(() => false);
        jest.spyOn(textArea, 'dispatchEvent');
        textArea.value = 'two';
        textArea.setSelectionRange(0, 0);
      });

      it('inserts the text', () => {
        commonUtils.insertText(textArea, 'one');

        expect(textArea.value).toBe('onetwo');
        expect(textArea.dispatchEvent).toHaveBeenCalled();
      });

      it('replaces the selection', () => {
        textArea.setSelectionRange(0, textArea.value.length);

        commonUtils.insertText(textArea, 'one');

        expect(textArea.value).toBe('one');
        expect(textArea.selectionStart).toBe(textArea.value.length);
      });

      it('removes selected text', () => {
        textArea.setSelectionRange(0, textArea.value.length);

        commonUtils.insertText(textArea, '');

        expect(textArea.value).toBe('');
      });
    });
  });

  describe('normalizedHeaders', () => {
    it('should upperCase all the header keys to keep them consistent', () => {
      const apiHeaders = {
        'X-Something-Workhorse': { workhorse: 'ok' },
        'x-something-nginx': { nginx: 'ok' },
      };

      const normalized = commonUtils.normalizeHeaders(apiHeaders);

      const WORKHORSE = 'X-SOMETHING-WORKHORSE';
      const NGINX = 'X-SOMETHING-NGINX';

      expect(normalized[WORKHORSE].workhorse).toBe('ok');
      expect(normalized[NGINX].nginx).toBe('ok');
    });
  });

  describe('parseIntPagination', () => {
    it('should parse to integers all string values and return pagination object', () => {
      const pagination = {
        'X-PER-PAGE': 10,
        'X-PAGE': 2,
        'X-TOTAL': 30,
        'X-TOTAL-PAGES': 3,
        'X-NEXT-PAGE': 3,
        'X-PREV-PAGE': 1,
      };

      const expectedPagination = {
        perPage: 10,
        page: 2,
        total: 30,
        totalPages: 3,
        nextPage: 3,
        previousPage: 1,
      };

      expect(commonUtils.parseIntPagination(pagination)).toEqual(expectedPagination);
    });
  });

  describe('isMetaKey', () => {
    it('should identify ctrlKey click on Windows/Linux', () => {
      const e = {
        metaKey: false,
        ctrlKey: true,
      };

      expect(commonUtils.isMetaKey(e)).toBe(true);
    });

    it('should identify metaKey click on macOS', () => {
      const e = {
        metaKey: true,
        ctrlKey: false,
      };

      expect(commonUtils.isMetaKey(e)).toBe(true);
    });

    it('should not identify shiftKey click as meta key', () => {
      const e = {
        metaKey: false,
        ctrlKey: false,
        shiftKey: true,
      };

      expect(commonUtils.isMetaKey(e)).toBe(false);
    });

    it('should not identify altKey click as meta key', () => {
      const e = {
        metaKey: false,
        ctrlKey: false,
        altKey: true,
      };

      expect(commonUtils.isMetaKey(e)).toBe(false);
    });
  });

  describe('isMetaClick', () => {
    it('should identify meta click on Windows/Linux', () => {
      const e = {
        metaKey: false,
        ctrlKey: true,
        which: 1,
      };

      expect(commonUtils.isMetaClick(e)).toBe(true);
    });

    it('should identify meta click on macOS', () => {
      const e = {
        metaKey: true,
        ctrlKey: false,
        which: 1,
      };

      expect(commonUtils.isMetaClick(e)).toBe(true);
    });

    it('should identify as meta click on middle-click or Mouse-wheel click', () => {
      const e = {
        metaKey: false,
        ctrlKey: false,
        which: 2,
      };

      expect(commonUtils.isMetaClick(e)).toBe(true);
    });
  });

  describe('isMetaEnterKeyPair', () => {
    it('should identify meta + enter click on Windows/Linux', () => {
      const e = {
        metaKey: false,
        ctrlKey: true,
        key: 'Enter',
      };

      expect(commonUtils.isMetaEnterKeyPair(e)).toBe(true);
    });

    it('should identify meta + enter click on macOS', () => {
      const e = {
        metaKey: true,
        ctrlKey: false,
        key: 'Enter',
      };

      expect(commonUtils.isMetaEnterKeyPair(e)).toBe(true);
    });

    it('should not return true if meta click without enter on Windows/Linux', () => {
      const e = {
        metaKey: false,
        ctrlKey: true,
      };

      expect(commonUtils.isMetaEnterKeyPair(e)).toBe(false);
    });

    it('should not return true if meta click without enter on macOS', () => {
      const e = {
        metaKey: true,
        ctrlKey: false,
      };

      expect(commonUtils.isMetaEnterKeyPair(e)).toBe(false);
    });
  });

  describe('parseBoolean', () => {
    it.each`
      input          | expected
      ${'true'}      | ${true}
      ${'false'}     | ${false}
      ${'something'} | ${false}
      ${null}        | ${false}
      ${true}        | ${true}
      ${false}       | ${false}
    `('returns $expected for $input', ({ input, expected }) => {
      expect(commonUtils.parseBoolean(input)).toBe(expected);
    });
  });

  describe('backOff', () => {
    beforeEach(() => {
      jest.spyOn(window, 'setTimeout');
    });

    it('solves the promise from the callback', () => {
      const expectedResponseValue = 'Success!';
      return commonUtils
        .backOff((next, stop) =>
          new Promise((resolve) => {
            resolve(expectedResponseValue);
          }).then((resp) => {
            stop(resp);
          }),
        )
        .then((respBackoff) => {
          expect(respBackoff).toBe(expectedResponseValue);
        });
    });

    it('catches the rejected promise from the callback', () => {
      const errorMessage = 'Mistakes were made!';
      return commonUtils
        .backOff((next, stop) => {
          new Promise((resolve, reject) => {
            reject(new Error(errorMessage));
          })
            .then((resp) => {
              stop(resp);
            })
            .catch((err) => stop(err));
        })
        .catch((errBackoffResp) => {
          expect(errBackoffResp instanceof Error).toBe(true);
          expect(errBackoffResp.message).toBe(errorMessage);
        });
    });

    it('solves the promise correctly after retrying a third time', () => {
      let numberOfCalls = 1;
      const expectedResponseValue = 'Success!';
      return commonUtils
        .backOff((next, stop) =>
          Promise.resolve(expectedResponseValue).then((resp) => {
            if (numberOfCalls < 3) {
              numberOfCalls += 1;
              next();
              jest.runOnlyPendingTimers();
            } else {
              stop(resp);
            }
          }),
        )
        .then((respBackoff) => {
          const timeouts = window.setTimeout.mock.calls.map(([, timeout]) => timeout);

          expect(timeouts).toEqual([2000, 4000]);
          expect(respBackoff).toBe(expectedResponseValue);
        });
    });

    it('rejects the backOff promise after timing out', () => {
      return commonUtils
        .backOff((next) => {
          next();
          jest.runOnlyPendingTimers();
        }, 64000)
        .catch((errBackoffResp) => {
          const timeouts = window.setTimeout.mock.calls.map(([, timeout]) => timeout);

          expect(timeouts).toEqual([2000, 4000, 8000, 16000, 32000, 32000]);
          expect(errBackoffResp instanceof Error).toBe(true);
          expect(errBackoffResp.message).toBe('BACKOFF_TIMEOUT');
        });
    });
  });

  describe('spriteIcon', () => {
    beforeEach(() => {
      window.gon.sprite_icons = 'icons.svg';
    });

    it('should return the svg for a linked icon', () => {
      expect(commonUtils.spriteIcon('test')).toEqual(
        '<svg ><use xlink:href="icons.svg#test" /></svg>',
      );
    });

    it('should set svg className when passed', () => {
      expect(commonUtils.spriteIcon('test', 'first-icon-class second-icon-class')).toEqual(
        '<svg class="first-icon-class second-icon-class"><use xlink:href="icons.svg#test" /></svg>',
      );
    });
  });

  describe('convertObjectProps*', () => {
    const mockConversionFunction = (prop) => `${prop}_converted`;
    const isEmptyObject = (obj) =>
      typeof obj === 'object' && obj !== null && Object.keys(obj).length === 0;

    const mockObjects = {
      convertObjectProps: {
        obj: {
          id: 1,
          group_name: 'GitLab.org',
          absolute_web_url: 'https://gitlab.com/gitlab-org/',
          milestones: ['12.3', '12.4'],
        },
        objNested: {
          project_name: 'GitLab CE',
          group_name: 'GitLab.org',
          license_type: 'MIT',
          tech_stack: {
            backend: 'Ruby',
            frontend_framework: 'Vue',
            database: 'PostgreSQL',
          },
          milestones: ['12.3', '12.4'],
        },
      },
      convertObjectPropsToCamelCase: {
        obj: {
          id: 1,
          group_name: 'GitLab.org',
          absolute_web_url: 'https://gitlab.com/gitlab-org/',
          milestones: ['12.3', '12.4'],
        },
        objNested: {
          project_name: 'GitLab CE',
          group_name: 'GitLab.org',
          license_type: 'MIT',
          tech_stack: {
            backend: 'Ruby',
            frontend_framework: 'Vue',
            database: 'PostgreSQL',
          },
          milestones: ['12.3', '12.4'],
        },
      },
      convertObjectPropsToSnakeCase: {
        obj: {
          id: 1,
          groupName: 'GitLab.org',
          absoluteWebUrl: 'https://gitlab.com/gitlab-org/',
          milestones: ['12.3', '12.4'],
        },
        objNested: {
          projectName: 'GitLab CE',
          groupName: 'GitLab.org',
          licenseType: 'MIT',
          techStack: {
            backend: 'Ruby',
            frontendFramework: 'Vue',
            database: 'PostgreSQL',
          },
          milestones: ['12.3', '12.4'],
        },
      },
      convertObjectPropsToLowerCase: {
        obj: {
          'Project-Name': 'GitLab CE',
          'Group-Name': 'GitLab.org',
          'License-Type': 'MIT',
          'Mile-Stones': ['12.3', '12.4'],
        },
        objNested: {
          'Project-Name': 'GitLab CE',
          'Group-Name': 'GitLab.org',
          'License-Type': 'MIT',
          'Tech-Stack': {
            'Frontend-Framework': 'Vue',
          },
          'Mile-Stones': ['12.3', '12.4'],
        },
      },
    };

    describe('convertObjectProps', () => {
      it('returns an empty object if `conversionFunction` parameter is not a function', () => {
        const result = commonUtils.convertObjectProps(null, mockObjects.convertObjectProps.obj);

        expect(isEmptyObject(result)).toBe(true);
      });
    });

    describe.each`
      functionName                       | mockObj                                          | mockObjNested
      ${'convertObjectProps'}            | ${mockObjects.convertObjectProps.obj}            | ${mockObjects.convertObjectProps.objNested}
      ${'convertObjectPropsToCamelCase'} | ${mockObjects.convertObjectPropsToCamelCase.obj} | ${mockObjects.convertObjectPropsToCamelCase.objNested}
      ${'convertObjectPropsToSnakeCase'} | ${mockObjects.convertObjectPropsToSnakeCase.obj} | ${mockObjects.convertObjectPropsToSnakeCase.objNested}
      ${'convertObjectPropsToLowerCase'} | ${mockObjects.convertObjectPropsToLowerCase.obj} | ${mockObjects.convertObjectPropsToLowerCase.objNested}
    `('$functionName', ({ functionName, mockObj, mockObjNested }) => {
      const testFunction =
        functionName === 'convertObjectProps'
          ? (obj, options = {}) =>
              commonUtils.convertObjectProps(mockConversionFunction, obj, options)
          : commonUtils[functionName];

      it('returns an empty object if `obj` parameter is null, undefined or an empty object', () => {
        expect(isEmptyObject(testFunction(null))).toBe(true);
        expect(isEmptyObject(testFunction())).toBe(true);
        expect(isEmptyObject(testFunction({}))).toBe(true);
      });

      it('converts object properties', () => {
        const expected = {
          convertObjectProps: {
            id_converted: 1,
            group_name_converted: 'GitLab.org',
            absolute_web_url_converted: 'https://gitlab.com/gitlab-org/',
            milestones_converted: ['12.3', '12.4'],
          },
          convertObjectPropsToCamelCase: {
            id: 1,
            groupName: 'GitLab.org',
            absoluteWebUrl: 'https://gitlab.com/gitlab-org/',
            milestones: ['12.3', '12.4'],
          },
          convertObjectPropsToSnakeCase: {
            id: 1,
            group_name: 'GitLab.org',
            absolute_web_url: 'https://gitlab.com/gitlab-org/',
            milestones: ['12.3', '12.4'],
          },
          convertObjectPropsToLowerCase: {
            'project-name': 'GitLab CE',
            'group-name': 'GitLab.org',
            'license-type': 'MIT',
            'mile-stones': ['12.3', '12.4'],
          },
        };

        expect(testFunction(mockObj)).toEqual(expected[functionName]);
      });

      it('does not deep-convert by default', () => {
        const expected = {
          convertObjectProps: {
            project_name_converted: 'GitLab CE',
            group_name_converted: 'GitLab.org',
            license_type_converted: 'MIT',
            tech_stack_converted: {
              backend: 'Ruby',
              frontend_framework: 'Vue',
              database: 'PostgreSQL',
            },
            milestones_converted: ['12.3', '12.4'],
          },
          convertObjectPropsToCamelCase: {
            projectName: 'GitLab CE',
            groupName: 'GitLab.org',
            licenseType: 'MIT',
            techStack: {
              backend: 'Ruby',
              frontend_framework: 'Vue',
              database: 'PostgreSQL',
            },
            milestones: ['12.3', '12.4'],
          },
          convertObjectPropsToSnakeCase: {
            project_name: 'GitLab CE',
            group_name: 'GitLab.org',
            license_type: 'MIT',
            tech_stack: {
              backend: 'Ruby',
              frontendFramework: 'Vue',
              database: 'PostgreSQL',
            },
            milestones: ['12.3', '12.4'],
          },
          convertObjectPropsToLowerCase: {
            'project-name': 'GitLab CE',
            'group-name': 'GitLab.org',
            'license-type': 'MIT',
            'tech-stack': {
              'Frontend-Framework': 'Vue',
            },
            'mile-stones': ['12.3', '12.4'],
          },
        };

        expect(testFunction(mockObjNested)).toEqual(expected[functionName]);
      });

      describe('with options', () => {
        describe('when options.deep is true', () => {
          const expected = {
            convertObjectProps: {
              project_name_converted: 'GitLab CE',
              group_name_converted: 'GitLab.org',
              license_type_converted: 'MIT',
              tech_stack_converted: {
                backend_converted: 'Ruby',
                frontend_framework_converted: 'Vue',
                database_converted: 'PostgreSQL',
              },
              milestones_converted: ['12.3', '12.4'],
            },
            convertObjectPropsToCamelCase: {
              projectName: 'GitLab CE',
              groupName: 'GitLab.org',
              licenseType: 'MIT',
              techStack: {
                backend: 'Ruby',
                frontendFramework: 'Vue',
                database: 'PostgreSQL',
              },
              milestones: ['12.3', '12.4'],
            },
            convertObjectPropsToSnakeCase: {
              project_name: 'GitLab CE',
              group_name: 'GitLab.org',
              license_type: 'MIT',
              tech_stack: {
                backend: 'Ruby',
                frontend_framework: 'Vue',
                database: 'PostgreSQL',
              },
              milestones: ['12.3', '12.4'],
            },
            convertObjectPropsToLowerCase: {
              'project-name': 'GitLab CE',
              'group-name': 'GitLab.org',
              'license-type': 'MIT',
              'tech-stack': {
                'frontend-framework': 'Vue',
              },
              'mile-stones': ['12.3', '12.4'],
            },
          };

          it('converts nested objects', () => {
            expect(testFunction(mockObjNested, { deep: true })).toEqual(expected[functionName]);
          });

          it('converts array of nested objects', () => {
            expect(testFunction([mockObjNested], { deep: true })).toEqual([expected[functionName]]);
          });

          it('converts array with child arrays', () => {
            expect(testFunction([[mockObjNested]], { deep: true })).toEqual([
              [expected[functionName]],
            ]);
          });
        });

        describe('when options.dropKeys is provided', () => {
          it('discards properties mentioned in `dropKeys` array', () => {
            const expected = {
              convertObjectProps: {
                project_name_converted: 'GitLab CE',
                license_type_converted: 'MIT',
                tech_stack_converted: {
                  backend: 'Ruby',
                  frontend_framework: 'Vue',
                  database: 'PostgreSQL',
                },
                milestones_converted: ['12.3', '12.4'],
              },
              convertObjectPropsToCamelCase: {
                projectName: 'GitLab CE',
                licenseType: 'MIT',
                techStack: {
                  backend: 'Ruby',
                  frontend_framework: 'Vue',
                  database: 'PostgreSQL',
                },
                milestones: ['12.3', '12.4'],
              },
              convertObjectPropsToSnakeCase: {
                project_name: 'GitLab CE',
                license_type: 'MIT',
                tech_stack: {
                  backend: 'Ruby',
                  frontendFramework: 'Vue',
                  database: 'PostgreSQL',
                },
                milestones: ['12.3', '12.4'],
              },
              convertObjectPropsToLowerCase: {
                'project-name': 'GitLab CE',
                'group-name': 'GitLab.org',
                'license-type': 'MIT',
                'tech-stack': {
                  'Frontend-Framework': 'Vue',
                },
                'mile-stones': ['12.3', '12.4'],
              },
            };

            const dropKeys = {
              convertObjectProps: ['group_name'],
              convertObjectPropsToCamelCase: ['group_name'],
              convertObjectPropsToSnakeCase: ['groupName'],
            };

            expect(
              testFunction(mockObjNested, {
                dropKeys: dropKeys[functionName],
              }),
            ).toEqual(expected[functionName]);
          });

          it('discards properties mentioned in `dropKeys` array when `deep` is true', () => {
            const expected = {
              convertObjectProps: {
                project_name_converted: 'GitLab CE',
                license_type_converted: 'MIT',
                tech_stack_converted: {
                  backend_converted: 'Ruby',
                  frontend_framework_converted: 'Vue',
                },
                milestones_converted: ['12.3', '12.4'],
              },
              convertObjectPropsToCamelCase: {
                projectName: 'GitLab CE',
                licenseType: 'MIT',
                techStack: {
                  backend: 'Ruby',
                  frontendFramework: 'Vue',
                },
                milestones: ['12.3', '12.4'],
              },
              convertObjectPropsToSnakeCase: {
                project_name: 'GitLab CE',
                license_type: 'MIT',
                tech_stack: {
                  backend: 'Ruby',
                  frontend_framework: 'Vue',
                },
                milestones: ['12.3', '12.4'],
              },
              convertObjectPropsToLowerCase: {
                'project-name': 'GitLab CE',
                'tech-stack': {
                  'frontend-framework': 'Vue',
                },
                'mile-stones': ['12.3', '12.4'],
              },
            };

            const dropKeys = {
              convertObjectProps: ['group_name', 'database'],
              convertObjectPropsToCamelCase: ['group_name', 'database'],
              convertObjectPropsToSnakeCase: ['groupName', 'database'],
              convertObjectPropsToLowerCase: ['Group-Name', 'License-Type'],
            };

            expect(
              testFunction(mockObjNested, {
                dropKeys: dropKeys[functionName],
                deep: true,
              }),
            ).toEqual(expected[functionName]);
          });
        });

        describe('when options.ignoreKeyNames is provided', () => {
          it('leaves properties mentioned in `ignoreKeyNames` array intact', () => {
            const expected = {
              convertObjectProps: {
                project_name_converted: 'GitLab CE',
                group_name: 'GitLab.org',
                license_type_converted: 'MIT',
                tech_stack_converted: {
                  backend: 'Ruby',
                  frontend_framework: 'Vue',
                  database: 'PostgreSQL',
                },
                milestones_converted: ['12.3', '12.4'],
              },
              convertObjectPropsToCamelCase: {
                projectName: 'GitLab CE',
                group_name: 'GitLab.org',
                licenseType: 'MIT',
                techStack: {
                  backend: 'Ruby',
                  frontend_framework: 'Vue',
                  database: 'PostgreSQL',
                },
                milestones: ['12.3', '12.4'],
              },
              convertObjectPropsToSnakeCase: {
                project_name: 'GitLab CE',
                groupName: 'GitLab.org',
                license_type: 'MIT',
                tech_stack: {
                  backend: 'Ruby',
                  frontendFramework: 'Vue',
                  database: 'PostgreSQL',
                },
                milestones: ['12.3', '12.4'],
              },
              convertObjectPropsToLowerCase: {
                'project-name': 'GitLab CE',
                'Group-Name': 'GitLab.org',
                'license-type': 'MIT',
                'tech-stack': {
                  'Frontend-Framework': 'Vue',
                },
                'mile-stones': ['12.3', '12.4'],
              },
            };

            const ignoreKeyNames = {
              convertObjectProps: ['group_name'],
              convertObjectPropsToCamelCase: ['group_name'],
              convertObjectPropsToSnakeCase: ['groupName'],
              convertObjectPropsToLowerCase: ['Group-Name'],
            };

            expect(
              testFunction(mockObjNested, {
                ignoreKeyNames: ignoreKeyNames[functionName],
              }),
            ).toEqual(expected[functionName]);
          });

          it('leaves properties mentioned in `ignoreKeyNames` array intact when `deep` is true', () => {
            const expected = {
              convertObjectProps: {
                project_name_converted: 'GitLab CE',
                group_name: 'GitLab.org',
                license_type_converted: 'MIT',
                tech_stack_converted: {
                  backend_converted: 'Ruby',
                  frontend_framework: 'Vue',
                  database_converted: 'PostgreSQL',
                },
                milestones_converted: ['12.3', '12.4'],
              },
              convertObjectPropsToCamelCase: {
                projectName: 'GitLab CE',
                group_name: 'GitLab.org',
                licenseType: 'MIT',
                techStack: {
                  backend: 'Ruby',
                  frontend_framework: 'Vue',
                  database: 'PostgreSQL',
                },
                milestones: ['12.3', '12.4'],
              },
              convertObjectPropsToSnakeCase: {
                project_name: 'GitLab CE',
                groupName: 'GitLab.org',
                license_type: 'MIT',
                tech_stack: {
                  backend: 'Ruby',
                  frontendFramework: 'Vue',
                  database: 'PostgreSQL',
                },
                milestones: ['12.3', '12.4'],
              },
              convertObjectPropsToLowerCase: {
                'project-name': 'GitLab CE',
                'group-name': 'GitLab.org',
                'license-type': 'MIT',
                'tech-stack': {
                  'Frontend-Framework': 'Vue',
                },
                'mile-stones': ['12.3', '12.4'],
              },
            };

            const ignoreKeyNames = {
              convertObjectProps: ['group_name', 'frontend_framework'],
              convertObjectPropsToCamelCase: ['group_name', 'frontend_framework'],
              convertObjectPropsToSnakeCase: ['groupName', 'frontendFramework'],
              convertObjectPropsToLowerCase: ['Frontend-Framework'],
            };

            expect(
              testFunction(mockObjNested, {
                deep: true,
                ignoreKeyNames: ignoreKeyNames[functionName],
              }),
            ).toEqual(expected[functionName]);
          });
        });
      });
    });
  });

  describe('roundOffFloat', () => {
    it('Rounds off decimal places of a float number with provided precision', () => {
      expect(commonUtils.roundOffFloat(3.141592, 3)).toBeCloseTo(3.142);
    });

    it('Rounds off a float number to a whole number when provided precision is zero', () => {
      expect(commonUtils.roundOffFloat(3.141592, 0)).toBeCloseTo(3);
      expect(commonUtils.roundOffFloat(3.5, 0)).toBeCloseTo(4);
    });

    it('Rounds off float number to nearest 0, 10, 100, 1000 and so on when provided precision is below 0', () => {
      expect(commonUtils.roundOffFloat(34567.14159, -1)).toBeCloseTo(34570);
      expect(commonUtils.roundOffFloat(34567.14159, -2)).toBeCloseTo(34600);
      expect(commonUtils.roundOffFloat(34567.14159, -3)).toBeCloseTo(35000);
      expect(commonUtils.roundOffFloat(34567.14159, -4)).toBeCloseTo(30000);
      expect(commonUtils.roundOffFloat(34567.14159, -5)).toBeCloseTo(0);
    });
  });

  describe('roundDownFloat', () => {
    it('Rounds down decimal places of a float number with provided precision', () => {
      expect(commonUtils.roundDownFloat(3.141592, 3)).toBe(3.141);
    });

    it('Rounds down a float number to a whole number when provided precision is zero', () => {
      expect(commonUtils.roundDownFloat(3.141592, 0)).toBe(3);
      expect(commonUtils.roundDownFloat(3.9, 0)).toBe(3);
    });

    it('Rounds down float number to nearest 0, 10, 100, 1000 and so on when provided precision is below 0', () => {
      expect(commonUtils.roundDownFloat(34567.14159, -1)).toBeCloseTo(34560);
      expect(commonUtils.roundDownFloat(34567.14159, -2)).toBeCloseTo(34500);
      expect(commonUtils.roundDownFloat(34567.14159, -3)).toBeCloseTo(34000);
      expect(commonUtils.roundDownFloat(34567.14159, -4)).toBeCloseTo(30000);
      expect(commonUtils.roundDownFloat(34567.14159, -5)).toBeCloseTo(0);
    });
  });

  describe('roundToNearestHalf', () => {
    it('Rounds decimals ot the nearest half', () => {
      expect(commonUtils.roundToNearestHalf(3.141592)).toBe(3);
      expect(commonUtils.roundToNearestHalf(3.41592)).toBe(3.5);
      expect(commonUtils.roundToNearestHalf(1.27)).toBe(1.5);
      expect(commonUtils.roundToNearestHalf(1.23)).toBe(1);
      expect(commonUtils.roundToNearestHalf(1.778)).toBe(2);
    });
  });

  describe('isScopedLabel', () => {
    it('returns true when `::` is present in label title', () => {
      expect(commonUtils.isScopedLabel({ title: 'foo::bar' })).toBe(true);
    });

    it('returns true when `::` is present in label name', () => {
      expect(commonUtils.isScopedLabel({ name: 'foo::bar' })).toBe(true);
    });

    it('returns false when `::` is not present', () => {
      expect(commonUtils.isScopedLabel({ title: 'foobar', name: 'foobar' })).toBe(false);
    });
  });

  describe('scopedLabelKey', () => {
    it.each`
      label                           | expectedLabelKey
      ${undefined}                    | ${''}
      ${''}                           | ${''}
      ${'title'}                      | ${'title'}
      ${'scoped::value'}              | ${'scoped'}
      ${'scoped::label::value'}       | ${'scoped::label'}
      ${'scoped::label-some::value'}  | ${'scoped::label-some'}
      ${'scoped::label::some::value'} | ${'scoped::label::some'}
    `('returns "$expectedLabelKey" when label is "$label"', ({ label, expectedLabelKey }) => {
      expect(commonUtils.scopedLabelKey({ title: label })).toBe(expectedLabelKey);
    });
  });

  describe('getDashPath', () => {
    it('returns the path following /-/', () => {
      expect(commonUtils.getDashPath('/some/-/url-with-dashes-/')).toEqual('url-with-dashes-/');
    });

    it('returns null when no path follows /-/', () => {
      expect(commonUtils.getDashPath('/some/url')).toEqual(null);
    });
  });

  describe('convertArrayToCamelCase', () => {
    it('returns a new array with snake_case string elements converted camelCase', () => {
      const result = commonUtils.convertArrayToCamelCase(['hello', 'hello_world']);

      expect(result).toEqual(['hello', 'helloWorld']);
    });
  });

  describe('convertArrayOfObjectsToCamelCase', () => {
    it('returns a new array with snake_case object property names converted camelCase', () => {
      const result = commonUtils.convertArrayOfObjectsToCamelCase([
        { hello: '' },
        { hello_world: '' },
      ]);

      expect(result).toEqual([{ hello: '' }, { helloWorld: '' }]);
    });
  });

  describe('isCurrentUser', () => {
    describe('when user is not signed in', () => {
      it('returns `false`', () => {
        window.gon.current_user_id = null;

        expect(commonUtils.isCurrentUser(1)).toBe(false);
      });
    });

    describe('when current user id does not match the provided user id', () => {
      it('returns `false`', () => {
        window.gon.current_user_id = 2;

        expect(commonUtils.isCurrentUser(1)).toBe(false);
      });
    });

    describe('when current user id matches the provided user id', () => {
      it('returns `true`', () => {
        window.gon.current_user_id = 1;

        expect(commonUtils.isCurrentUser(1)).toBe(true);
      });
    });

    describe('when provided user id is a string and it matches current user id', () => {
      it('returns `true`', () => {
        window.gon.current_user_id = 1;

        expect(commonUtils.isCurrentUser('1')).toBe(true);
      });
    });
  });

  describe('cloneWithoutReferences', () => {
    it('clones the provided object', () => {
      const obj = {
        foo: 'bar',
        cool: 1337,
        nested: {
          peanut: 'butter',
        },
        arrays: [0, 1, 2],
      };

      const cloned = commonUtils.cloneWithoutReferences(obj);

      expect(cloned).toMatchObject({
        foo: 'bar',
        cool: 1337,
        nested: {
          peanut: 'butter',
        },
        arrays: [0, 1, 2],
      });
    });

    it('does not persist object references after cloning', () => {
      const ref = {
        foo: 'bar',
      };

      const obj = {
        ref,
      };

      const cloned = commonUtils.cloneWithoutReferences(obj);

      expect(cloned.ref).toMatchObject({ foo: 'bar' });
      expect(cloned.ref === ref).toBe(false);
    });
  });

  describe('isDefaultCiConfig', () => {
    it('returns true when the path is the default CI config path', () => {
      expect(commonUtils.isDefaultCiConfig('.gitlab-ci.yml')).toBe(true);
    });

    it('returns false when the path is not the default CI config path', () => {
      expect(commonUtils.isDefaultCiConfig('some/other/path.yml')).toBe(false);
    });
  });

  describe('hasCiConfigExtension', () => {
    it('returns true when the path is the default CI config path', () => {
      expect(commonUtils.hasCiConfigExtension('.gitlab-ci.yml')).toBe(true);
    });

    it('returns true when the path has a CI config extension', () => {
      expect(commonUtils.hasCiConfigExtension('some/path.gitlab-ci.yml')).toBe(true);
    });

    it('returns false when the path does not have a CI config extension', () => {
      expect(commonUtils.hasCiConfigExtension('some/other/path.yml')).toBe(false);
    });
  });
});
