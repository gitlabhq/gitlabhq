import { createWrapper } from '@vue/test-utils';
import Vue from 'vue';

import { initExpiresAtField, initProjectsField } from '~/access_tokens';
import * as ExpiresAtField from '~/access_tokens/components/expires_at_field.vue';
import * as ProjectsField from '~/access_tokens/components/projects_field.vue';

describe('access tokens', () => {
  const FakeComponent = Vue.component('FakeComponent', {
    props: {
      inputAttrs: {
        type: Object,
        required: true,
      },
    },
    render: () => null,
  });

  beforeEach(() => {
    window.gon = { features: { personalAccessTokensScopedToProjects: true } };
  });

  afterEach(() => {
    document.body.innerHTML = '';
  });

  describe.each`
    initFunction          | mountSelector                    | expectedComponent
    ${initExpiresAtField} | ${'js-access-tokens-expires-at'} | ${ExpiresAtField}
    ${initProjectsField}  | ${'js-access-tokens-projects'}   | ${ProjectsField}
  `('$initFunction', ({ initFunction, mountSelector, expectedComponent }) => {
    describe('when mount element exists', () => {
      beforeEach(() => {
        const mountEl = document.createElement('div');
        mountEl.classList.add(mountSelector);

        const input = document.createElement('input');
        input.setAttribute('name', 'foo-bar');
        input.setAttribute('id', 'foo-bar');
        input.setAttribute('placeholder', 'Foo bar');
        input.setAttribute('value', '1,2');

        mountEl.appendChild(input);

        document.body.appendChild(mountEl);

        // Mock component so we don't have to deal with mocking Apollo
        // eslint-disable-next-line no-param-reassign
        expectedComponent.default = FakeComponent;
      });

      it('mounts component and sets `inputAttrs` prop', async () => {
        const vueInstance = await initFunction();

        const wrapper = createWrapper(vueInstance);
        const component = wrapper.findComponent(FakeComponent);

        expect(component.exists()).toBe(true);
        expect(component.props('inputAttrs')).toEqual({
          name: 'foo-bar',
          id: 'foo-bar',
          value: '1,2',
          placeholder: 'Foo bar',
        });
      });
    });

    describe('when mount element does not exist', () => {
      it('returns `null`', () => {
        expect(initFunction()).toBe(null);
      });
    });
  });
});
