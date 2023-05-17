import { GlAlert, GlBadge, GlTabs } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import EditorTab from '~/ci/pipeline_editor/components/ui/editor_tab.vue';

const mockContent1 = 'MOCK CONTENT 1';
const mockContent2 = 'MOCK CONTENT 2';

const MockSourceEditor = {
  template: '<div>EDITOR</div>',
};

describe('~/ci/pipeline_editor/components/ui/editor_tab.vue', () => {
  let wrapper;
  let mockChildMounted = jest.fn();

  const MockChild = {
    props: ['content'],
    template: '<div>{{content}}</div>',
    mounted() {
      mockChildMounted(this.content);
    },
  };

  const MockTabbedContent = {
    components: {
      EditorTab,
      GlTabs,
      MockChild,
    },
    template: `
        <gl-tabs>
          <editor-tab title="Tab 1" :title-link-attributes="{ 'data-testid': 'tab1-btn' }" :lazy="true">
            <mock-child content="${mockContent1}"/>
          </editor-tab>
          <editor-tab title="Tab 2" :title-link-attributes="{ 'data-testid': 'tab2-btn' }" :lazy="true" badge-title="NEW">
            <mock-child content="${mockContent2}"/>
          </editor-tab>
        </gl-tabs>
      `,
  };

  const createMockedWrapper = () => {
    wrapper = mount(MockTabbedContent);
  };

  const createWrapper = ({ props } = {}) => {
    wrapper = mount(EditorTab, {
      propsData: {
        title: 'Tab 1',
        ...props,
      },
      slots: {
        default: MockSourceEditor,
      },
    });
  };

  const findSlotComponent = () => wrapper.findComponent(MockSourceEditor);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findBadges = () => wrapper.findAllComponents(GlBadge);

  beforeEach(() => {
    mockChildMounted = jest.fn();
  });

  it('tabs are mounted lazily', () => {
    createMockedWrapper();

    expect(mockChildMounted).toHaveBeenCalledTimes(0);
  });

  it('first tab is only mounted after nextTick', async () => {
    createMockedWrapper();

    await nextTick();

    expect(mockChildMounted).toHaveBeenCalledTimes(1);
    expect(mockChildMounted).toHaveBeenCalledWith(mockContent1);
  });

  describe('alerts', () => {
    describe('unavailable state', () => {
      beforeEach(() => {
        createWrapper({ props: { isUnavailable: true } });
      });

      it('shows the invalid alert when the status is invalid', () => {
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        expect(alert.text()).toContain(wrapper.vm.$options.i18n.unavailable);
      });
    });

    describe('invalid state', () => {
      beforeEach(() => {
        createWrapper({ props: { isInvalid: true } });
      });

      it('shows the invalid alert when the status is invalid', () => {
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        expect(alert.text()).toBe(wrapper.vm.$options.i18n.invalid);
      });
    });

    describe('empty state', () => {
      const text = 'my custom alert message';

      beforeEach(() => {
        createWrapper({
          props: { isEmpty: true, emptyMessage: text },
        });
      });

      it('displays an empty message', () => {
        createWrapper({
          props: { isEmpty: true },
        });

        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        expect(alert.text()).toBe(
          'This tab will be usable when the CI/CD configuration file is populated with valid syntax.',
        );
      });

      it('can have a custom empty message', () => {
        const alert = findAlert();

        expect(alert.exists()).toBe(true);
        expect(alert.text()).toBe(text);
      });
    });
  });

  describe('showing the tab content depending on `isEmpty`, `isUnavailable` and `isInvalid`', () => {
    it.each`
      isEmpty      | isUnavailable | isInvalid    | showSlotComponent | text
      ${undefined} | ${undefined}  | ${undefined} | ${true}           | ${'renders'}
      ${false}     | ${false}      | ${false}     | ${true}           | ${'renders'}
      ${undefined} | ${true}       | ${true}      | ${false}          | ${'hides'}
      ${true}      | ${false}      | ${false}     | ${false}          | ${'hides'}
      ${false}     | ${true}       | ${false}     | ${false}          | ${'hides'}
      ${false}     | ${false}      | ${true}      | ${false}          | ${'hides'}
    `(
      '$text the slot component when isEmpty:$isEmpty, isUnavailable:$isUnavailable and isInvalid:$isInvalid',
      ({ isEmpty, isUnavailable, isInvalid, showSlotComponent }) => {
        createWrapper({
          props: { isEmpty, isUnavailable, isInvalid },
        });
        expect(findSlotComponent().exists()).toBe(showSlotComponent);
        expect(findAlert().exists()).toBe(!showSlotComponent);
      },
    );
  });

  describe('user interaction', () => {
    const clickTab = async (testid) => {
      wrapper.find(`[data-testid="${testid}"]`).trigger('click');
      await nextTick();
    };

    beforeEach(() => {
      createMockedWrapper();
    });

    it('mounts a tab once after selecting it', async () => {
      await clickTab('tab2-btn');

      expect(mockChildMounted).toHaveBeenCalledTimes(2);
      expect(mockChildMounted).toHaveBeenNthCalledWith(1, mockContent1);
      expect(mockChildMounted).toHaveBeenNthCalledWith(2, mockContent2);
    });

    it('mounts each tab once after selecting each', async () => {
      await clickTab('tab2-btn');
      await clickTab('tab1-btn');
      await clickTab('tab2-btn');

      expect(mockChildMounted).toHaveBeenCalledTimes(2);
      expect(mockChildMounted).toHaveBeenNthCalledWith(1, mockContent1);
      expect(mockChildMounted).toHaveBeenNthCalledWith(2, mockContent2);
    });
  });

  describe('valid state', () => {
    beforeEach(() => {
      createMockedWrapper();
    });

    it('renders correct number of badges', () => {
      expect(findBadges()).toHaveLength(1);
      expect(findBadges().at(0).text()).toBe('NEW');
    });
  });
});
