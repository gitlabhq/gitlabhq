import { shallowMount } from '@vue/test-utils';
import ChangedFileIcon from '~/vue_shared/components/changed_file_icon.vue';
import Icon from '~/vue_shared/components/icon.vue';

const changedFile = () => ({ changed: true });
const stagedFile = () => ({ changed: false, staged: true });
const changedAndStagedFile = () => ({ changed: true, staged: true });
const newFile = () => ({ changed: true, tempFile: true });
const unchangedFile = () => ({ changed: false, tempFile: false, staged: false, deleted: false });

describe('Changed file icon', () => {
  let wrapper;

  const factory = (props = {}) => {
    wrapper = shallowMount(ChangedFileIcon, {
      propsData: {
        file: changedFile(),
        showTooltip: true,
        ...props,
      },
      attachToDocument: true,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const findIcon = () => wrapper.find(Icon);
  const findIconName = () => findIcon().props('name');
  const findIconClasses = () => findIcon().classes();
  const findTooltipText = () => wrapper.attributes('title');

  it('with isCentered true, adds center class', () => {
    factory({
      isCentered: true,
    });

    expect(wrapper.classes('ml-auto')).toBe(true);
  });

  it('with isCentered false, does not center', () => {
    factory({
      isCentered: false,
    });

    expect(wrapper.classes('ml-auto')).toBe(false);
  });

  it('with showTooltip false, does not show tooltip', () => {
    factory({
      showTooltip: false,
    });

    expect(findTooltipText()).toBeFalsy();
  });

  describe.each`
    file                      | iconName                 | tooltipText                           | desc
    ${changedFile()}          | ${'file-modified'}       | ${'Unstaged modification'}            | ${'with file changed'}
    ${stagedFile()}           | ${'file-modified-solid'} | ${'Staged modification'}              | ${'with file staged'}
    ${changedAndStagedFile()} | ${'file-modified'}       | ${'Unstaged and staged modification'} | ${'with file changed and staged'}
    ${newFile()}              | ${'file-addition'}       | ${'Unstaged addition'}                | ${'with file new'}
  `('$desc', ({ file, iconName, tooltipText }) => {
    beforeEach(() => {
      factory({ file });
    });

    it('renders icon', () => {
      expect(findIconName()).toBe(iconName);
      expect(findIconClasses()).toContain(iconName);
    });

    it('renders tooltip text', () => {
      expect(findTooltipText()).toBe(tooltipText);
    });
  });

  describe('with file unchanged', () => {
    beforeEach(() => {
      factory({
        file: unchangedFile(),
      });
    });

    it('does not show icon', () => {
      expect(findIcon().exists()).toBe(false);
    });

    it('does not have tooltip text', () => {
      expect(findTooltipText()).toBeFalsy();
    });
  });

  it('with size set, sets icon size', () => {
    const size = 8;

    factory({
      file: changedFile(),
      size,
    });

    expect(findIcon().props('size')).toBe(size);
  });

  it.each`
    showStagedIcon | iconName                 | desc
    ${true}        | ${'file-modified-solid'} | ${'with showStagedIcon true, renders staged icon'}
    ${false}       | ${'file-modified'}       | ${'with showStagedIcon false, renders regular icon'}
  `('$desc', ({ showStagedIcon, iconName }) => {
    factory({
      file: stagedFile(),
      showStagedIcon,
    });

    expect(findIconName()).toEqual(iconName);
  });
});
