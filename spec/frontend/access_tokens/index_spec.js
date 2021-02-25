import { createWrapper } from '@vue/test-utils';

import waitForPromises from 'helpers/wait_for_promises';

import { initExpiresAtField, initProjectsField } from '~/access_tokens';
import ExpiresAtField from '~/access_tokens/components/expires_at_field.vue';
import ProjectsField from '~/access_tokens/components/projects_field.vue';

describe('access tokens', () => {
  beforeEach(() => {
    window.gon = { features: { personalAccessTokensScopedToProjects: true } };
  });

  afterEach(() => {
    document.body.innerHTML = '';
    window.gon = {};
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

        mountEl.appendChild(input);

        document.body.appendChild(mountEl);
      });

      it(`mounts component and sets \`inputAttrs\` prop`, async () => {
        const wrapper = createWrapper(initFunction());

        // Wait for dynamic imports to resolve
        await waitForPromises();

        const component = wrapper.findComponent(expectedComponent);

        expect(component.exists()).toBe(true);
        expect(component.props('inputAttrs')).toEqual({
          name: 'foo-bar',
          id: 'foo-bar',
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
