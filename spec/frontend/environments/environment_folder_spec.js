import { GlIcon, GlLink, GlBadge } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import EnvironmentsFolder from '~/environments/components/environment_folder.vue';
import { resolvedEnvironmentsApp } from './graphql/mock_data';

describe('~/environments/components/environments_folder.vue', () => {
  let wrapper;

  const findIcon = () => wrapper.findComponent(GlIcon);
  const findLink = () => wrapper.findComponent(GlLink);
  const findBadge = () => wrapper.findComponent(GlBadge);

  const createWrapper = () =>
    mountExtended(EnvironmentsFolder, {
      propsData: {
        nestedEnvironment: resolvedEnvironmentsApp.environments[0],
      },
    });

  describe('default', () => {
    beforeEach(() => {
      wrapper = createWrapper();
    });

    it('displays the correct icon', () => {
      const icon = findIcon();

      expect(icon.props()).toMatchObject({
        name: 'folder',
        variant: 'subtle',
      });
    });

    it('displays a link to an environments folder', () => {
      const link = findLink();

      expect(link.attributes('href')).toBe('/h5bp/html5-boilerplate/-/environments/folders/review');
      expect(link.text()).toContain('review');
    });

    it('displays a badge with a total environments count', () => {
      const badge = findBadge();

      expect(badge.text()).toBe('2');
    });

    it('displays a badge inside a link element', () => {
      const link = findLink();

      expect(link.findComponent(GlBadge).exists()).toBe(true);
    });
  });
});
