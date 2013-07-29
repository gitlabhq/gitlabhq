----------------------------------------------

Table of Contents  
=================

----------------------------------------------

[GitLab Flavored Markdown](#toc_3)
-------------------------------
[Newlines](#toc_4)
[Multiple underscores in words](#toc_5)
[URL autolinking](#toc_6)
[Code and Syntax Highlighting](#toc_7)
[Emoji](#toc_8)
[Special GitLab references](#toc_9)



[Standard Markdown](#toc_10)
------------------------------
[Headers](#toc_11)
[Emphasis](#toc_20)
[Lists](#toc_21)
[Links](#toc_22)
[Images](#toc_23)
[Blockquotes](#toc_24)
[Inline HTML](#toc_25)
[Horizontal Rule](#toc_26)
[Line Breaks](#toc_27)

[References](#toc_28)
---------------------

----------------------------------------------

<a name="gfm" />
GitLab Flavored Markdown (GFM) 
==============================
For GitLab we developed something we call "GitLab Flavored Markdown" (GFM). It extends the standard Markdown in a few significant ways to add some useful functionality.

You can use GFM in

* commit messages
* comments
* wall posts
* issues
* merge requests
* milestones
* wiki pages

<a name="newlines" />
Newlines
--------
The biggest difference that GFM introduces is in the handling of linebreaks. With traditional Markdown you can hard wrap paragraphs of text and they will be combined into a single paragraph. We find this to be the cause of a huge number of unintentional formatting errors. GFM treats newlines in paragraph-like content as real line breaks, which is probably what you intended.

The next paragraph contains two phrases separated by a single newline character:

    Roses are red
    Violets are blue

Roses are red
Violets are blue
    
<a name="underscores" />
Multiple underscores in words
-----------------------------
It is not reasonable to italicize just _part_ of a word, especially when you're dealing with code and names that often appear with multiple underscores. Therefore, GFM ignores multiple underscores in words.

    perform_complicated_task
    do_this_and_do_that_and_another_thing

perform_complicated_task
do_this_and_do_that_and_another_thing

<a name="autolink" />
URL autolinking
---------------
GFM will autolink standard URLs you copy and paste into your text.
So if you want to link to a URL (instead of a textural link), you can simply put the URL in verbatim and it will be turned into a link to that URL.

    http://www.google.com

http://www.google.com

<a name="code"/>
## Code and Syntax Highlighting

Blocks of code are either fenced by lines with three back-ticks <code>```</code>, or are indented with four spaces. Only the fenced code blocks support syntax highlighting.


```no-highlight
Inline `code` has `back-ticks around` it.
```

Inline `code` has `back-ticks around` it.

Example:

    ```javascript
    var s = "JavaScript syntax highlighting";
    alert(s);
    ```
         
    ```python
    def function():
        #indenting works just fine in the fenced code block
        s = "Python syntax highlighting"
        print s
    ```
         
    ```ruby
    require 'redcarpet'
    markdown = Redcarpet.new("Hello World!")
    puts markdown.to_html
    ```

    ```
    No language indicated, so no syntax highlighting. 
    s = "There is no highlighting for this."
    But let's throw in a <b>tag</b>.
    ```

becomes:

```javascript
var s = "JavaScript syntax highlighting";
alert(s);
```

```python
def function():
    #indenting works just fine in the fenced code block
    s = "Python syntax highlighting"
    print s
```

```ruby
require 'redcarpet'
markdown = Redcarpet.new("Hello World!")
puts markdown.to_html
```

```
No language indicated, so no syntax highlighting.
s = "There is no highlighting for this."
But let's throw in a <b>tag</b>.
```

<a name="emoji"/>
Emoji
-----

	Sometimes you want to be :cool: and add some :sparkles: to your :speech_balloon:. Well we have a :gift: for you:

	:exclamation: You can use emoji anywhere GFM is supported. :sunglasses:

	You can use it to point out a :bug: or warn about :monkey:patches. And if someone improves your really :snail: code, send them a :bouquet: or some :candy:. People will :heart: you for that.

	If you are :new: to this, don't be :fearful:. You can easily join the emoji :circus_tent:. All you need to do is to :book: up on the supported codes.

	Consult the [Emoji Cheat Sheet](http://www.emoji-cheat-sheet.com/) for a list of all supported emoji codes. :thumbsup: 

Sometimes you want to be :cool: and add some :sparkles: to your :speech_balloon:. Well we have a :gift: for you:

:exclamation: You can use emoji anywhere GFM is supported. :sunglasses:

You can use it to point out a :bug: or warn about :monkey:patches. And if someone improves your really :snail: code, send them a :bouquet: or some :candy:. People will :heart: you for that.

If you are :new: to this, don't be :fearful:. You can easily join the emoji :circus_tent:. All you need to do is to :book: up on the supported codes.

Consult the [Emoji Cheat Sheet](http://www.emoji-cheat-sheet.com/) for a list of all supported emoji codes. :thumbsup: 

<a name="special"/>
Special GitLab References
-----

GFM recognized special references.
You can easily reference e.g. a team member, an issue, or a commit within a project.
GFM will turn that reference into a link so you can navigate between them easily.


GFM will recognize the following:

* @foo : for team members
* #123 : for issues
* !123 : for merge requests
* $123 : for snippets
* 1234567 : for commits
* [file](path/to/file) : for file references

<a name="standard"/>

----------------------------------
# Standard Markdown

----------------------------------
<a name="headers"/>
## Headers

```no-highlight
# H1
## H2
### H3
#### H4
##### H5
###### H6

Alternatively, for H1 and H2, an underline-ish style:

Alt-H1
======

Alt-H2
------
```

# H1
## H2
### H3
#### H4
##### H5
###### H6

Alternatively, for H1 and H2, an underline-ish style:

Alt-H1
======

Alt-H2
------

<a name="emphasis"/>
## Emphasis

```no-highlight
Emphasis, aka italics, with *asterisks* or _underscores_.

Strong emphasis, aka bold, with **asterisks** or __underscores__.

Combined emphasis with **asterisks and _underscores_**.

Strikethrough uses two tildes. ~~Scratch this.~~
```

Emphasis, aka italics, with *asterisks* or _underscores_.

Strong emphasis, aka bold, with **asterisks** or __underscores__.

Combined emphasis with **asterisks and _underscores_**.

Strikethrough uses two tildes. ~~Scratch this.~~


<a name="lists"/>
## Lists

```no-highlight
1. First ordered list item
2. Another item
  * Unordered sub-list. 
1. Actual numbers don't matter, just that it's a number
  1. Ordered sub-list
4. And another item.  
   
   Some text that should be aligned with the above item.

* Unordered list can use asterisks
- Or minuses
+ Or pluses
```

1. First ordered list item
2. Another item
  * Unordered sub-list. 
1. Actual numbers don't matter, just that it's a number
  1. Ordered sub-list
4. And another item.  
   
   Some text that should be aligned with the above item.

* Unordered list can use asterisks
- Or minuses
+ Or pluses

<a name="links"/>
## Links

There are two ways to create links.

    [I'm an inline-style link](https://www.google.com)

    [I'm a reference-style link][Arbitrary case-insensitive reference text]

    [I'm a relative reference to a repository file](../blob/master/LICENSE)

    [You can use numbers for reference-style link definitions][1]

    Or leave it empty and use the [link text itself][]

    Some text to show that the reference links can follow later.

    [arbitrary case-insensitive reference text]: https://www.mozilla.org
    [1]: http://slashdot.org
    [link text itself]: http://www.reddit.com

[I'm an inline-style link](https://www.google.com)

[I'm a reference-style link][Arbitrary case-insensitive reference text]

[I'm a relative reference to a repository file](../blob/master/LICENSE)

[You can use numbers for reference-style link definitions][1]

Or leave it empty and use the [link text itself][]

Some text to show that the reference links can follow later.

[arbitrary case-insensitive reference text]: https://www.mozilla.org
[1]: http://slashdot.org
[link text itself]: http://www.reddit.com

<a name="images"/>
## Images

    Here's our logo (hover to see the title text):

    Inline-style: 
    ![alt text](/assets/logo-white.png "Logo Title Text 1")

    Reference-style: 
    ![alt text][logo]

    [logo]: /assets/logo-white.png "Logo Title Text 2"

Here's our logo (hover to see the title text):

Inline-style: 
![alt text](/assets/logo-white.png "Logo Title Text 1")

Reference-style: 
![alt text][logo]

[logo]: /assets/logo-white.png "Logo Title Text 2"

<a name="blockquotes"/>
## Blockquotes

```no-highlight
> Blockquotes are very handy in email to emulate reply text.
> This line is part of the same quote.

Quote break.

> This is a very long line that will still be quoted properly when it wraps. Oh boy let's keep writing to make sure this is long enough to actually wrap for everyone. Oh, you can *put* **Markdown** into a blockquote. 
```

> Blockquotes are very handy in email to emulate reply text.
> This line is part of the same quote.

Quote break.

> This is a very long line that will still be quoted properly when it wraps. Oh boy let's keep writing to make sure this is long enough to actually wrap for everyone. Oh, you can *put* **Markdown** into a blockquote. 

<a name="html"/>
## Inline HTML

You can also use raw HTML in your Markdown, and it'll mostly work pretty well. 

```no-highlight
<dl>
  <dt>Definition list</dt>
  <dd>Is something people use sometimes.</dd>

  <dt>Markdown in HTML</dt>
  <dd>Does *not* work **very** well. Use HTML <em>tags</em>.</dd>
</dl>
```

<dl>
  <dt>Definition list</dt>
  <dd>Is something people use sometimes.</dd>

  <dt>Markdown in HTML</dt>
  <dd>Does *not* work **very** well. Use HTML <em>tags</em>.</dd>
</dl>

<a name="hr"/>
## Horizontal Rule

```
Three or more...

---

Hyphens

***

Asterisks

___

Underscores
```

Three or more...

---

Hyphens

***

Asterisks

___

Underscores

<a name="lines"/>
## Line Breaks

My basic recommendation for learning how line breaks work is to experiment and discover -- hit &lt;Enter&gt; once (i.e., insert one newline), then hit it twice (i.e., insert two newlines), see what happens. You'll soon learn to get what you want. "Markdown Toggle" is your friend. 

Here are some things to try out:

```
Here's a line for us to start with.

This line is separated from the one above by two newlines, so it will be a *separate paragraph*.

This line is also a separate paragraph, but...
This line is only separated by a single newline, so it's a separate line in the *same paragraph*.
```

Here's a line for us to start with.

This line is separated from the one above by two newlines, so it will be a *separate paragraph*.

This line is also begins a separate paragraph, but...  
This line is only separated by a single newline, so it's a separate line in the *same paragraph*.

------------

<a name="references"/>
## References

* This document leveraged heavily from the [Markdown-Cheatsheet](https://github.com/adam-p/markdown-here/wiki/Markdown-Cheatsheet).
* The [Markdown Syntax Guide](http://daringfireball.net/projects/markdown/syntax) at Daring Fireball is an excellent resource for a detailed explanation of standard markdown.
* [Dillinger.io](http://dillinger.io) is a handy tool for testing standard markdown.
