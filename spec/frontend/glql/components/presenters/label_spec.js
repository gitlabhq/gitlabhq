import { GlLabel } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import setWindowLocation from 'helpers/set_window_location_helper';
import LabelPresenter from '~/glql/components/presenters/label.vue';
import { MOCK_LABELS } from '../../mock_data';

const MOCK_LABEL = MOCK_LABELS.nodes[0];

describe('LabelPresenter', () => {
  let wrapper;

  const createWrapper = ({ data }) => {
    wrapper = shallowMountExtended(LabelPresenter, {
      propsData: { data },
    });
  };

  const findGlLabel = () => wrapper.findComponent(GlLabel);

  describe('for a group label', () => {
    beforeEach(() => {
      setWindowLocation('https://gitlab.test/groups/foo-bar/-/work_items/1');
    });

    it('correctly renders a label', () => {
      createWrapper({ data: MOCK_LABEL });

      const glLabel = findGlLabel();

      expect(glLabel.attributes('scoped')).toBeUndefined();
      expect(glLabel.attributes('title')).toBe(MOCK_LABEL.title);
      expect(glLabel.attributes('target')).toBe('/groups/foo-bar/-/issues?label=Label%201');
    });

    it('correctly renders a scoped label', () => {
      createWrapper({ data: { ...MOCK_LABEL, title: 'Scoped::Label' } });

      const glLabel = findGlLabel();

      expect(glLabel.attributes('scoped')).toBe('true');
      expect(glLabel.attributes('title')).toBe('Scoped::Label');
      expect(glLabel.attributes('target')).toContain(
        '/groups/foo-bar/-/issues?label=Scoped%3A%3ALabel',
      );
    });
  });

  describe('for a project label', () => {
    beforeEach(() => {
      setWindowLocation('https://gitlab.test/foo-bar/baz/-/work_items/1');
    });

    it('correctly renders a label', () => {
      createWrapper({ data: MOCK_LABEL });

      const glLabel = findGlLabel();

      expect(glLabel.attributes('scoped')).toBeUndefined();
      expect(glLabel.attributes('title')).toBe(MOCK_LABEL.title);
      expect(glLabel.attributes('target')).toBe('/foo-bar/baz/-/issues?label=Label%201');
    });

    it('correctly renders a scoped label', () => {
      createWrapper({ data: { ...MOCK_LABEL, title: 'Scoped::Label' } });

      const glLabel = findGlLabel();

      expect(glLabel.attributes('scoped')).toBe('true');
      expect(glLabel.attributes('title')).toBe('Scoped::Label');
      expect(glLabel.attributes('target')).toContain(
        '/foo-bar/baz/-/issues?label=Scoped%3A%3ALabel',
      );
    });
  });
});
