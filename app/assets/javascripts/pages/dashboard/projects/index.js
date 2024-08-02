import ProjectsList from '~/projects_list';
import { initYourWorkProjects } from '~/projects/your_work';
import { initProjectsFilteredSearchAndSort } from '~/projects/filtered_search_and_sort';

new ProjectsList(); // eslint-disable-line no-new
initYourWorkProjects();
initProjectsFilteredSearchAndSort();
