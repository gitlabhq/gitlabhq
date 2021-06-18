import { GlAlert, GlTabs } from '@gitlab/ui';
import { mount } from '@vue/test-utils';
import { nextTick } from 'vue';
import EditorTab from '~/pipeline_editor/components/ui/editor_tab.vue';

const mockContent1 = 'MOCK CONTENT 1';
const mockContent2 = 'MOCK CONTENT 2';

const MockSourceEditor = {
  template: '<div>EDITOR</div>',
};

describe('~/pipeline_editor/components/ui/editor_tab.vue', () => {
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
          <editor-tab :title-link-attributes="{ 'data-testid': 'tab1-btn' }" :lazy="true">
            <mock-child content="${mockContent1}"/>
          </editor-tab>
          <editor-tab :title-link-attributes="{ 'data-testid': 'tab2-btn' }" :lazy="true">
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
      propsData: props,
      slots: {
        default: MockSourceEditor,
      },
    });
  };

  const findSlotComponent = () => wrapper.findComponent(MockSourceEditor);
  const findAlert = () => wrapper.findComponent(GlAlert);

  beforeEach(() => {
    mockChildMounted = jest.fn();
  });

  it('tabs are mounted lazily', async () => {
    createMockedWrapper();

    expect(mockChildMounted).toHaveBeenCalledTimes(0);
  });

  it('first tab is only mounted after nextTick', async () => {
    createMockedWrapper();

    await nextTick();

    expect(mockChildMounted).toHaveBeenCalledTimes(1);
    expect(mockChildMounted).toHaveBeenCalledWith(mockContent1);
  });

  describe('showing the tab content depending on `isEmpty` and `isInvalid`', () => {
    it.each`
      isEmpty      | isInvalid    | showSlotComponent | text
      ${undefined} | ${undefined} | ${true}           | ${'renders'}
      ${false}     | ${false}     | ${true}           | ${'renders'}
      ${undefined} | ${true}      | ${false}          | ${'hides'}
      ${true}      | ${false}     | ${false}          | ${'hides'}
      ${false}     | ${true}      | ${false}          | ${'hides'}
    `(
      '$text the slot component when isEmpty:$isEmpty and isInvalid:$isInvalid',
      ({ isEmpty, isInvalid, showSlotComponent }) => {
        createWrapper({
          props: { isEmpty, isInvalid },
        });
        expect(findSlotComponent().exists()).toBe(showSlotComponent);
        expect(findAlert().exists()).toBe(!showSlotComponent);
      },
    );

    it('can have a custom empty message', () => {
      const text = 'my custom alert message';
      createWrapper({ props: { isEmpty: true, emptyMessage: text } });

      const alert = findAlert();

      expect(alert.exists()).toBe(true);
      expect(alert.text()).toBe(text);
    });
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
});
