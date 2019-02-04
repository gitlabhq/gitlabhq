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
