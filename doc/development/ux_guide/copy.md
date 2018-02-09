# Copy

The copy for GitLab is clear and direct. We strike a clear balance between professional and friendly. We can empathesize with users (such as celebrating completing all Todos), and remain respectful of the importance of the work. We are that trusted, friendly coworker that is helpful and understanding.

The copy and messaging is a core part of the experience of GitLab and the conversation with our users. Follow the below conventions throughout GitLab.

Portions of this page are inspired by work found in the [Material Design guidelines][material design].

>**Note:**
We are currently inconsistent with this guidance. Images below are created to illustrate the point. As this guidance is refined, we will ensure that our experiences align.

## Contents
* [Brevity](#brevity)
* [Capitalization and punctuation](#capitalization-and-punctuation)
* [Terminology](#terminology)

---

## Brevity
Users will skim content, rather than read text carefully.
When familiar with a web app, users rely on muscle memory, and may read even less when moving quickly.
A good experience should quickly orient a user, regardless of their experience, to the purpose of the current screen. This should happen without the user having to consciously read long strings of text.
In general, text is burdensome and adds cognitive load. This is especially pronounced in a powerful productivity tool such as GitLab.
We should _not_ rely on words as a crutch to explain the purpose of a screen.
The current navigation and composition of the elements on the screen should get the user 95% there, with the remaining 5% being specific elements such as text.
This means that, as a rule, copy should be very short. A long message or label is a red flag hinting at design that needs improvement.

>**Example:**
Use `Add` instead of `Add issue` as a button label.
Preferably use context and placement of controls to make it obvious what clicking on them will do.

---

## Capitalization and punctuation

### Case
Use sentence case for titles, headings, labels, menu items, and buttons. Use title case when referring to [features][features] or [products][products]. Note that some features are also objects (e.g. “Merge Requests” and “merge requests”).

| :white_check_mark: Do | :no_entry_sign: Don’t |
| --- | --- |
| Add issues to the Issue Board feature in GitLab Hosted | Add Issues To The Issue Board Feature In GitLab Hosted |

### Avoid periods
Avoid using periods in solitary sentences in these elements:

* Labels
* Hover text
* Bulleted lists
* Modal body text

Periods should be used for:

* Lists or modals with multiple sentences
* Any sentence followed by a link

| :white_check_mark: **Do** place periods after sentences followed by a link | :no_entry_sign: **Don’t** place periods after a link if it‘s not followed by a sentence |
| --- | --- |
| Mention someone to notify them. [Learn more](#) | Mention someone to notify them. [Learn more](#). |

| :white_check_mark: **Do** skip periods after solo sentences of body text | :no_entry_sign: **Don’t** place periods after body text if there is only a single sentence |
| --- | --- |
| To see the available commands, enter `/gitlab help` | To see the available commands, enter `/gitlab help`. |

### Use contractions
Don’t make a sentence harder to understand just to follow this rule. For example, “do not” can give more emphasis than “don’t” when needed.

| :white_check_mark: Do | :no_entry_sign: Don’t |
| --- | --- |
| it’s, can’t, wouldn’t, you’re, you’ve, haven’t, don’t | it is, cannot, would not, it’ll, should’ve |

### Use numerals for numbers
Use “1, 2, 3” instead of “one, two, three” for numbers. One exception is when mixing uses of numbers, such as “Enter two 3s.”

| :white_check_mark: Do | :no_entry_sign: Don’t |
| --- | --- |
| 3 new commits | Three new commits |

### Punctuation
Omit punctuation after phrases and labels to create a cleaner and more readable interface. Use punctuation to add clarity or be grammatically correct.

| Punctuation mark | Copy and paste | HTML entity | Unicode | Mac shortcut | Windows shortcut | Description |
|---|---|---|---|---|---|---|
| Period | **.** | | | | | Omit for single sentences in affordances like labels, hover text, bulleted lists, and modal body text.<br><br>Use in lists or modals with multiple sentences, and any sentence followed by a link or inline code.<br><br>Place inside quotation marks unless you’re telling the reader what to enter and it’s ambiguous whether to include the period. |
| Comma | **,** | | | | | Place inside quotation marks.<br><br>Use a [serial comma][serial comma] in lists of three or more terms. |
| Exclamation point | **!** | | | | | Avoid exclamation points as they tend to come across as shouting. Some exceptions include greetings or congratulatory messages. |
| Colon | **:** | `&#58;` | `\u003A` | | | Omit from labels, for example, in the labels for fields in a form. |
| Apostrophe | **’** | `&rsquo;` | `\u2019` | <kbd>⌥ Option</kbd>+<kbd>⇧ Shift</kbd>+<kbd>]</kbd> | <kbd>Alt</kbd>+<kbd>0 1 4 6</kbd> | Use for contractions (I’m, you’re, ’89) and to show possession.<br><br>To show possession, add an *’s* to all singular common nouns and names, even if they already end in an *s*: “Look into this worker process’s log.” For singular proper names ending in *s*, use only an apostrophe: “James’ commits.” For plurals of a single letter, add an *’s*: “Dot your i’s and cross your t’s.”<br><br>Omit for decades or acronyms: “the 1990s”, “MRs.” |
| Quotation marks | **“**<br><br>**”**<br><br>**‘**<br><br>**’** | `&ldquo;`<br><br>`&rdquo;`<br><br>`&lsquo;`<br><br>`&rsquo;` | `\u201C`<br><br>`\u201D`<br><br>`\u2018`<br><br>`\u2019` | <kbd>⌥ Option</kbd>+<kbd>[</kbd><br><br><kbd>⌥ Option</kbd>+<kbd>⇧ Shift</kbd>+<kbd>[</kbd><br><br><kbd>⌥ Option</kbd>+<kbd>]</kbd><br><br><kbd>⌥ Option</kbd>+<kbd>⇧ Shift</kbd>+<kbd>]</kbd> | <kbd>Alt</kbd>+<kbd>0 1 4 7</kbd><br><br><kbd>Alt</kbd>+<kbd>0 1 4 8</kbd><br><br><kbd>Alt</kbd>+<kbd>0 1 4 5</kbd><br><br><kbd>Alt</kbd>+<kbd>0 1 4 6</kbd> | Use proper quotation marks (also known as smart quotes, curly quotes, or typographer’s quotes) for quotes. Single quotation marks are used for quotes inside of quotes.<br><br>The right single quotation mark symbol is also used for apostrophes.<br><br>Don’t use primes, straight quotes, or free-standing accents for quotation marks. |
| Primes | **′**<br><br>**″** | `&prime;`<br><br>`&Prime;` | `\u2032`<br><br>`\u2033` | | <kbd>Alt</kbd>+<kbd>8 2 4 2</kbd><br><br><kbd>Alt</kbd>+<kbd>8 2 4 3</kbd> | Use prime (′) only in abbreviations for feet, arcminutes, and minutes: 3° 15′<br><br>Use double-prime (″) only in abbreviations for inches, arcseconds, and seconds: 3° 15′ 35″<br><br>Don’t use quotation marks, straight quotes, or free-standing accents for primes. |
| Straight quotes and accents | **"**<br><br>**'**<br><br>**`**<br><br>**´** | `&quot;`<br><br>`&#39;`<br><br>`&#96;`<br><br>`&acute;` | `\u0022`<br><br>`\u0027`<br><br>`\u0060`<br><br>`\u00B4` | | | Don’t use straight quotes or free-standing accents for primes or quotation marks.<br><br>Proper typography never uses straight quotes. They are left over from the age of typewriters and their only modern use is for code. |
| Ellipsis | **…** | `&hellip;` | | <kbd>⌥ Option</kbd>+<kbd>;</kbd> | <kbd>Alt</kbd>+<kbd>0 1 3 3</kbd> | Use to indicate an action in progress (“Downloading…”) or incomplete or truncated text. No space before the ellipsis.<br><br>Omit from menu items or buttons that open a modal or start some other process. |
| Chevrons | **«**<br><br>**»**<br><br>**‹**<br><br>**›**<br><br>**<**<br><br>**>** | `&#171;`<br><br>`&#187;`<br><br>`&#8249;`<br><br>`&#8250;`<br><br>`&lt;`<br><br>`&gt;` | `\u00AB`<br><br>`\u00BB`<br><br>`\u2039`<br><br>`\u203A`<br><br>`\u003C`<br><br>`\u003E`<br><br> | | | Omit from links or buttons that open another page or move to the next or previous step in a process. Also known as angle brackets, angular quote brackets, or guillemets. |
| Em dash | **—** | `&mdash;` | `\u2014` | <kbd>⌥ Option</kbd>+<kbd>⇧ Shift</kbd>+<kbd>-</kbd> | <kbd>Alt</kbd>+<kbd>0 1 5 1</kbd> | Avoid using dashes to separate text. If you must use dashes for this purpose — like this — use an em dash surrounded by spaces. |
| En dash | **–** | `&ndash;` | `\u2013` | <kbd>⌥ Option</kbd>+<kbd>-</kbd> | <kbd>Alt</kbd>+<kbd>0 1 5 0</kbd> | Use an en dash without spaces instead of a hyphen to indicate a range of values, such as numbers, times, and dates: “3–5 kg”, “8:00 AM–12:30 PM”, “10–17 Jan” |
| Hyphen | **-** | | | | | Use to represent negative numbers, or to avoid ambiguity in adjective-noun or noun-participle pairs. Example: “anti-inflammatory”; “5-mile walk.”<br><br>Omit in commonly understood terms and adverbs that end in *ly*: “frontend”, “greatly improved performance.”<br><br>Omit in the term “open source.” |
| Parentheses | **( )** | | | | | Use only to define acronyms or jargon: “Secure web connections are based on a technology called SSL (the secure sockets layer).”<br><br>Avoid other uses and instead rewrite the text, or use dashes or commas to set off the information. If parentheses are required: If the parenthetical is a complete, independent sentence, place the period inside the parentheses; if not, the period goes outside. |

When using the <kbd>Alt</kbd> keystrokes in Windows, use the numeric keypad, not the row of numbers above the alphabet, and be sure Num Lock is turned on.

---

## Terminology
Only use the terms below.

When using verbs or adjectives:
* If the context clearly refers to the object, use them alone. Example: `Edit` or `Closed`
* If the context isn’t clear enough, use them with the object. Example: `Edit issue` or `Closed issues`

### Search

| Term | Use |
| ---- | --- |
| Search | When using all metadata to add criteria that match/don't match. Search can also affect ordering, by ranking best results. |
| Filter | When taking a single criteria that removes items within a list that match/don't match. Filters do not affect ordering. |
| Sort   | Orders a list based on a single or grouped criteria |

### Projects and Groups

| Term | Use | :no_entry_sign: Don't |
| ---- | --- | ----- |
| Members | When discussing the people who are a part of a project or a group. | Don't use `users`. |

### Issues

#### Adjectives (states)

| Term | :no_entry_sign: Don’t |
| ---- | --- |
| Open | Don’t use `Pending` or `Created` |
| Closed | Don’t use `Archived` |
| Deleted | Don’t use `Removed` or `Trashed` |

#### Verbs (actions)

| Term | Use | :no_entry_sign: Don’t |
| ---- | --- | --- |
| New | Although it’s not a verb, `New` is a common standard and used for entering the creation mode of a non-existent issue | Don’t use `Create`, `Open`, or `Add` |
| Create | Only to indicate when or who created an issue ||
| Add | Associate an existing issue with an item or a list of items | Don’t use `New` or `Create` |
| View | Open the detail page of an issue | Don’t use `Open` or `See` |
| Edit | Enter the editing mode of an issue | Don’t use `Change`, `Modify` or `Update` |
| Submit | Finalize the *creation* process of an issue | Don’t use `Add`, `Create`, `New`, `Open`, `Save` or `Save changes` |
| Save | Finalize the *editing* process of an issue | Don’t use `Edit`, `Modify`, `Update`, `Submit`, or `Save changes` |
| Cancel | Cancel the *creation* or *editing* process of an issue | Don’t use `Back`, `Close`, or `Discard` |
| Close | Close an open issue | Don’t use `Archive` |
| Re-open | Re-open a closed issue | Don’t use `Open` |
| Delete | Permanently remove an issue from the system | Don’t use `Remove` |
| Remove | Remove the association an issue with an item or a list of items | Don’t use `Delete` |

### Merge requests

#### Adjectives (states)

| Term |
| ---- |
| Open |
| Merged |

#### Verbs (actions)

| Term | Use | :no_entry_sign: Don’t |
| ---- | --- | --- |
| Add | Add a merge request | Do not use `create` or `new` |
| View | View an open or merged merge request ||
| Edit | Edit an open or merged merge request| Do not use `update` |
| Approve | Approve an open merge request ||
| Remove approval, unapproved | Remove approval of an open merge request | Do not use `unapprove` as that is not an English word|
| Merge | Merge an open merge request ||

### Comments & Discussions

#### Comment
A **comment** is a written piece of text that users of GitLab can create. Comments have the meta data of author and timestamp. Comments can be added in a variety of contexts, such as issues, merge requests, and discussions.

#### Discussion
A **discussion** is a group of 1 or more comments. A discussion can include subdiscussions. Some discussions have the special capability of being able to be **resolved**. Both the comments in the discussion and the discussion itself can be resolved.

## Modals

- Destruction buttons should be clear and always say what they are destroying.
  E.g., `Delete page` instead of just `Delete`.
- If the copy describes another action the user can take instead of the
  destructive one, provide a way for them to do that as a secondary button.
- Avoid the word `cancel` or `canceled` in the descriptive copy. It can be
  confusing when you then see the `Cancel` button.

see also: guidelines for [modal components](components.md#modals)

---

Portions of this page are modifications based on work created and shared by the [Android Open Source Project][android project] and used according to terms described in the [Creative Commons 2.5 Attribution License][creative commons].

[material design]: https://material.io/guidelines/
[features]: https://about.gitlab.com/features/ "GitLab features page"
[products]: https://about.gitlab.com/products/ "GitLab products page"
[serial comma]: https://en.wikipedia.org/wiki/Serial_comma "“Serial comma” in Wikipedia"
[android project]: http://source.android.com/
[creative commons]: http://creativecommons.org/licenses/by/2.5/
