import { findByText } from '@testing-library/dom';

export const waitForText = async (text, container = document) => findByText(container, text);
