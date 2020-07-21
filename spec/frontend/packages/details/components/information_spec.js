import { shallowMount } from '@vue/test-utils';
import PackageInformation from '~/packages/details/components/information.vue';
import ClipboardButton from '~/vue_shared/components/clipboard_button.vue';
import { GlLink } from '@gitlab/ui';

describe('PackageInformation', () => {
  let wrapper;

  const gitlabLink = 'https://gitlab.com';
  const testInformation = [
    {
      label: 'Information one',
      value: 'Information value one',
    },
    {
      label: 'Information two',
      value: 'Information value two',
    },
    {
      label: 'Information three',
      value: 'Information value three',
    },
  ];

  function createComponent(props = {}) {
    const propsData = {
      information: testInformation,
      ...props,
    };

    wrapper = shallowMount(PackageInformation, {
      propsData,
    });
  }

  const headingSelector = () => wrapper.find('.card-header > strong');
  const copyButton = () => wrapper.findAll(ClipboardButton);
  const informationSelector = () => wrapper.findAll('ul.content-list li');
  const informationRowText = index =>
    informationSelector()
      .at(index)
      .text();
  const informationLink = () => wrapper.find(GlLink);

  afterEach(() => {
    if (wrapper) wrapper.destroy();
  });

  it('renders the information block with default heading', () => {
    createComponent();

    expect(headingSelector()).toExist();
    expect(headingSelector().text()).toBe('Package information');
  });

  it('renders a custom supplied heading', () => {
    const heading = 'A custom heading';

    createComponent({
      heading,
    });

    expect(headingSelector()).toExist();
    expect(headingSelector().text()).toBe(heading);
  });

  it('renders the supplied information', () => {
    createComponent();

    expect(informationSelector()).toHaveLength(testInformation.length);
    expect(informationRowText(0)).toContain(testInformation[0].value);
    expect(informationRowText(1)).toContain(testInformation[1].value);
    expect(informationRowText(2)).toContain(testInformation[2].value);
  });

  it('renders a link when the information is of type link', () => {
    createComponent({
      information: [
        {
          label: 'Information link',
          value: gitlabLink,
          type: 'link',
        },
      ],
    });

    const link = informationLink();

    expect(link.exists()).toBe(true);
    expect(link.text()).toBe(gitlabLink);
    expect(link.attributes('href')).toBe(gitlabLink);
  });

  describe('copy button', () => {
    it('does not render by default', () => {
      createComponent();

      expect(copyButton().exists()).toBe(false);
    });

    it('does render when the prop is set and has correct text set', () => {
      createComponent({ showCopy: true });

      expect(copyButton()).toHaveLength(testInformation.length);
      expect(copyButton().at(0).vm.text).toBe(testInformation[0].value);
      expect(copyButton().at(1).vm.text).toBe(testInformation[1].value);
      expect(copyButton().at(2).vm.text).toBe(testInformation[2].value);
    });
  });
});
