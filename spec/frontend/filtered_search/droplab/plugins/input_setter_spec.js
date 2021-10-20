import InputSetter from '~/filtered_search/droplab/plugins/input_setter';

describe('InputSetter', () => {
  let testContext;

  beforeEach(() => {
    testContext = {};
  });

  describe('init', () => {
    beforeEach(() => {
      testContext.config = { InputSetter: {} };
      testContext.hook = { config: testContext.config };
      testContext.inputSetter = {
        addEvents: jest.fn(),
      };

      InputSetter.init.call(testContext.inputSetter, testContext.hook);
    });

    it('should set .hook', () => {
      expect(testContext.inputSetter.hook).toBe(testContext.hook);
    });

    it('should set .config', () => {
      expect(testContext.inputSetter.config).toBe(testContext.config.InputSetter);
    });

    it('should set .eventWrapper', () => {
      expect(testContext.inputSetter.eventWrapper).toEqual({});
    });

    it('should call .addEvents', () => {
      expect(testContext.inputSetter.addEvents).toHaveBeenCalled();
    });

    describe('if config.InputSetter is not set', () => {
      beforeEach(() => {
        testContext.config = { InputSetter: undefined };
        testContext.hook = { config: testContext.config };

        InputSetter.init.call(testContext.inputSetter, testContext.hook);
      });

      it('should set .config to an empty object', () => {
        expect(testContext.inputSetter.config).toEqual({});
      });

      it('should set hook.config to an empty object', () => {
        expect(testContext.hook.config.InputSetter).toEqual({});
      });
    });
  });

  describe('addEvents', () => {
    beforeEach(() => {
      testContext.hook = {
        list: {
          list: {
            addEventListener: jest.fn(),
          },
        },
      };
      testContext.inputSetter = { eventWrapper: {}, hook: testContext.hook, setInputs: () => {} };

      InputSetter.addEvents.call(testContext.inputSetter);
    });

    it('should set .eventWrapper.setInputs', () => {
      expect(testContext.inputSetter.eventWrapper.setInputs).toEqual(expect.any(Function));
    });

    it('should call .addEventListener', () => {
      expect(testContext.hook.list.list.addEventListener).toHaveBeenCalledWith(
        'click.dl',
        testContext.inputSetter.eventWrapper.setInputs,
      );
    });
  });

  describe('removeEvents', () => {
    beforeEach(() => {
      testContext.hook = {
        list: {
          list: {
            removeEventListener: jest.fn(),
          },
        },
      };
      testContext.eventWrapper = {
        setInputs: jest.fn(),
      };
      testContext.inputSetter = { eventWrapper: testContext.eventWrapper, hook: testContext.hook };

      InputSetter.removeEvents.call(testContext.inputSetter);
    });

    it('should call .removeEventListener', () => {
      expect(testContext.hook.list.list.removeEventListener).toHaveBeenCalledWith(
        'click.dl',
        testContext.eventWrapper.setInputs,
      );
    });
  });

  describe('setInputs', () => {
    beforeEach(() => {
      testContext.event = { detail: { selected: {} } };
      testContext.config = [0, 1];
      testContext.inputSetter = { config: testContext.config, setInput: () => {} };

      jest.spyOn(testContext.inputSetter, 'setInput').mockImplementation(() => {});

      InputSetter.setInputs.call(testContext.inputSetter, testContext.event);
    });

    it('should call .setInput for each config element', () => {
      const allArgs = testContext.inputSetter.setInput.mock.calls;

      expect(allArgs.length).toEqual(2);

      allArgs.forEach((args, i) => {
        expect(args[0]).toBe(testContext.config[i]);
        expect(args[1]).toBe(testContext.event.detail.selected);
      });
    });

    describe('if config isnt an array', () => {
      beforeEach(() => {
        testContext.inputSetter = { config: {}, setInput: () => {} };

        InputSetter.setInputs.call(testContext.inputSetter, testContext.event);
      });

      it('should set .config to an array with .config as the first element', () => {
        expect(testContext.inputSetter.config).toEqual([{}]);
      });
    });
  });

  describe('setInput', () => {
    beforeEach(() => {
      testContext.selectedItem = { getAttribute: () => {} };
      testContext.input = { value: 'oldValue', tagName: 'INPUT', hasAttribute: () => {} };
      testContext.config = { valueAttribute: {}, input: testContext.input };
      testContext.inputSetter = { hook: { trigger: {} } };
      testContext.newValue = 'newValue';

      jest.spyOn(testContext.selectedItem, 'getAttribute').mockReturnValue(testContext.newValue);
      jest.spyOn(testContext.input, 'hasAttribute').mockReturnValue(false);

      InputSetter.setInput.call(
        testContext.inputSetter,
        testContext.config,
        testContext.selectedItem,
      );
    });

    it('should call .getAttribute', () => {
      expect(testContext.selectedItem.getAttribute).toHaveBeenCalledWith(
        testContext.config.valueAttribute,
      );
    });

    it('should call .hasAttribute', () => {
      expect(testContext.input.hasAttribute).toHaveBeenCalledWith(undefined);
    });

    it('should set the value of the input', () => {
      expect(testContext.input.value).toBe(testContext.newValue);
    });

    describe('if no config.input is provided', () => {
      beforeEach(() => {
        testContext.config = { valueAttribute: {} };
        testContext.trigger = { value: 'oldValue', tagName: 'INPUT', hasAttribute: () => {} };
        testContext.inputSetter = { hook: { trigger: testContext.trigger } };

        InputSetter.setInput.call(
          testContext.inputSetter,
          testContext.config,
          testContext.selectedItem,
        );
      });

      it('should set the value of the hook.trigger', () => {
        expect(testContext.trigger.value).toBe(testContext.newValue);
      });
    });

    describe('if the input tag is not INPUT', () => {
      beforeEach(() => {
        testContext.input = { textContent: 'oldValue', tagName: 'SPAN', hasAttribute: () => {} };
        testContext.config = { valueAttribute: {}, input: testContext.input };

        InputSetter.setInput.call(
          testContext.inputSetter,
          testContext.config,
          testContext.selectedItem,
        );
      });

      it('should set the textContent of the input', () => {
        expect(testContext.input.textContent).toBe(testContext.newValue);
      });
    });

    describe('if there is an inputAttribute', () => {
      beforeEach(() => {
        testContext.selectedItem = { getAttribute: () => {} };
        testContext.input = { id: 'oldValue', hasAttribute: () => {}, setAttribute: () => {} };
        testContext.inputSetter = { hook: { trigger: {} } };
        testContext.newValue = 'newValue';
        testContext.inputAttribute = 'id';
        testContext.config = {
          valueAttribute: {},
          input: testContext.input,
          inputAttribute: testContext.inputAttribute,
        };

        jest.spyOn(testContext.selectedItem, 'getAttribute').mockReturnValue(testContext.newValue);
        jest.spyOn(testContext.input, 'hasAttribute').mockReturnValue(true);
        jest.spyOn(testContext.input, 'setAttribute').mockImplementation(() => {});

        InputSetter.setInput.call(
          testContext.inputSetter,
          testContext.config,
          testContext.selectedItem,
        );
      });

      it('should call setAttribute', () => {
        expect(testContext.input.setAttribute).toHaveBeenCalledWith(
          testContext.inputAttribute,
          testContext.newValue,
        );
      });

      it('should not set the value or textContent of the input', () => {
        expect(testContext.input.value).not.toBe('newValue');
        expect(testContext.input.textContent).not.toBe('newValue');
      });
    });
  });

  describe('destroy', () => {
    beforeEach(() => {
      testContext.inputSetter = {
        removeEvents: jest.fn(),
      };

      InputSetter.destroy.call(testContext.inputSetter);
    });

    it('should call .removeEvents', () => {
      expect(testContext.inputSetter.removeEvents).toHaveBeenCalled();
    });
  });
});
