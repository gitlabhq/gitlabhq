import { findByText } from '@testing-library/dom';

export const waitForText = (text, container = document) => findByText(container, text);
