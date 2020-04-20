import { mount } from '@vue/test-utils';
import { GlButton, GlFormInput } from '@gitlab/ui';
import { AWS_ACCESS_KEY_ID, AWS_DEFAULT_REGION } from '~/ci_variable_list/constants';
import CiKeyField from '~/ci_variable_list/components/ci_key_field.vue';

import {
  awsTokens,
  awsTokenList,
} from '~/ci_variable_list/components/ci_variable_autocomplete_tokens';

const doTimes = (num, fn) => {
  for (let i = 0; i < num; i += 1) {
    fn();
  }
};

describe('Ci Key field', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = mount({
      data() {
        return {
          inputVal: '',
          tokens: awsTokenList,
        };
      },
      components: { CiKeyField },
      template: `
        <div>
          <ci-key-field
            v-model="inputVal"
            :token-list="tokens"
          />
        </div>
      `,
    });
  };

  const findDropdown = () => wrapper.find('#ci-variable-dropdown');
  const findDropdownOptions = () => wrapper.findAll(GlButton).wrappers.map(item => item.text());
  const findInput = () => wrapper.find(GlFormInput);
  const findInputValue = () => findInput().element.value;
  const setInput = val => findInput().setValue(val);
  const clickDown = () => findInput().trigger('keydown.down');

  afterEach(() => {
    wrapper.destroy();
  });

  describe('match and filter functionality', () => {
    beforeEach(() => {
      createComponent();
    });

    it('is closed when the input is empty', () => {
      expect(findInput().isVisible()).toBe(true);
      expect(findInputValue()).toBe('');
      expect(findDropdown().isVisible()).toBe(false);
    });

    it('is open when the input text matches a token', () => {
      setInput('AWS');
      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdown().isVisible()).toBe(true);
      });
    });

    it('shows partial matches at string start', () => {
      setInput('AWS');
      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdown().isVisible()).toBe(true);
        expect(findDropdownOptions()).toEqual(awsTokenList);
      });
    });

    it('shows partial matches mid-string', () => {
      setInput('D');
      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdown().isVisible()).toBe(true);
        expect(findDropdownOptions()).toEqual([
          awsTokens[AWS_ACCESS_KEY_ID].name,
          awsTokens[AWS_DEFAULT_REGION].name,
        ]);
      });
    });

    it('is closed when the text does not match', () => {
      setInput('elephant');
      return wrapper.vm.$nextTick().then(() => {
        expect(findDropdown().isVisible()).toBe(false);
      });
    });
  });

  describe('keyboard navigation in dropdown', () => {
    beforeEach(() => {
      createComponent();
    });

    describe('on down arrow + enter', () => {
      it('selects the next item in the list and closes the dropdown', () => {
        setInput('AWS');
        return wrapper.vm
          .$nextTick()
          .then(() => {
            findInput().trigger('keydown.down');
            findInput().trigger('keydown.enter');
            return wrapper.vm.$nextTick();
          })
          .then(() => {
            expect(findInputValue()).toBe(awsTokenList[0]);
          });
      });

      it('loops to the top when it reaches the bottom', () => {
        setInput('AWS');
        return wrapper.vm
          .$nextTick()
          .then(() => {
            doTimes(findDropdownOptions().length + 1, clickDown);
            findInput().trigger('keydown.enter');
            return wrapper.vm.$nextTick();
          })
          .then(() => {
            expect(findInputValue()).toBe(awsTokenList[0]);
          });
      });
    });

    describe('on up arrow + enter', () => {
      it('selects the previous item in the list and closes the dropdown', () => {
        setInput('AWS');
        return wrapper.vm
          .$nextTick()
          .then(() => {
            doTimes(3, clickDown);
            findInput().trigger('keydown.up');
            findInput().trigger('keydown.enter');
            return wrapper.vm.$nextTick();
          })
          .then(() => {
            expect(findInputValue()).toBe(awsTokenList[1]);
          });
      });

      it('loops to the bottom when it reaches the top', () => {
        setInput('AWS');
        return wrapper.vm
          .$nextTick()
          .then(() => {
            findInput().trigger('keydown.down');
            findInput().trigger('keydown.up');
            findInput().trigger('keydown.enter');
            return wrapper.vm.$nextTick();
          })
          .then(() => {
            expect(findInputValue()).toBe(awsTokenList[awsTokenList.length - 1]);
          });
      });
    });

    describe('on enter with no item highlighted', () => {
      it('does not select any item and closes the dropdown', () => {
        setInput('AWS');
        return wrapper.vm
          .$nextTick()
          .then(() => {
            findInput().trigger('keydown.enter');
            return wrapper.vm.$nextTick();
          })
          .then(() => {
            expect(findInputValue()).toBe('AWS');
          });
      });
    });

    describe('on click', () => {
      it('selects the clicked item regardless of arrow highlight', () => {
        setInput('AWS');
        return wrapper.vm
          .$nextTick()
          .then(() => {
            wrapper.find(GlButton).trigger('click');
            return wrapper.vm.$nextTick();
          })
          .then(() => {
            expect(findInputValue()).toBe(awsTokenList[0]);
          });
      });
    });

    describe('on tab', () => {
      it('selects entered text, closes dropdown', () => {
        setInput('AWS');
        return wrapper.vm
          .$nextTick()
          .then(() => {
            findInput().trigger('keydown.tab');
            doTimes(2, clickDown);
            return wrapper.vm.$nextTick();
          })
          .then(() => {
            expect(findInputValue()).toBe('AWS');
            expect(findDropdown().isVisible()).toBe(false);
          });
      });
    });

    describe('on esc', () => {
      describe('when dropdown is open', () => {
        it('closes dropdown and does not select anything', () => {
          setInput('AWS');
          return wrapper.vm
            .$nextTick()
            .then(() => {
              findInput().trigger('keydown.esc');
              return wrapper.vm.$nextTick();
            })
            .then(() => {
              expect(findInputValue()).toBe('AWS');
              expect(findDropdown().isVisible()).toBe(false);
            });
        });
      });

      describe('when dropdown is closed', () => {
        it('clears the input field', () => {
          setInput('elephant');
          return wrapper.vm
            .$nextTick()
            .then(() => {
              expect(findDropdown().isVisible()).toBe(false);
              findInput().trigger('keydown.esc');
              return wrapper.vm.$nextTick();
            })
            .then(() => {
              expect(findInputValue()).toBe('');
            });
        });
      });
    });
  });
});
