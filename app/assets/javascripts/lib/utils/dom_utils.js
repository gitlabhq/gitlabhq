import { isInIssuePage, isInMRPage, isInEpicPage } from './common_utils';

export const addClassIfElementExists = (element, className) => {
  if (element) {
    element.classList.add(className);
  }
};

export const isInVueNoteablePage = () => isInIssuePage() || isInEpicPage() || isInMRPage();

export const canScrollUp = ({ scrollTop }, margin = 0) => scrollTop > margin;

export const canScrollDown = ({ scrollTop, offsetHeight, scrollHeight }, margin = 0) =>
  scrollTop + offsetHeight < scrollHeight - margin;

export const toggleContainerClasses = (containerEl, classList) => {
  if (containerEl) {
    // eslint-disable-next-line array-callback-return
    Object.entries(classList).map(([key, value]) => {
      if (value) {
        containerEl.classList.add(key);
      } else {
        containerEl.classList.remove(key);
      }
    });
  }
};
